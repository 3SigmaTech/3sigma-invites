/**
 * This class contains unit tests for validating the CalendarInvite class
 */

@isTest(SeeAllData = true)
private class Test_CalendarInvite
{
    static testMethod void testCalendarInviteBase()
    {
        //return;
        Test.startTest();
        try
        {
            CalendarInviteBase.LoadResponseInput testLoadResponseInput = new CalendarInviteBase.LoadResponseInput();
            CalendarInviteBase.InviteResponse testInviteResponse = new CalendarInviteBase.InviteResponse(testLoadResponseInput);
            
            CalendarInviteBase.UpdateTimezoneInput testUpdateTimezoneInput = new CalendarInviteBase.UpdateTimezoneInput(testLoadResponseInput);
            CalendarInviteBase.UpdateTimezoneResult testUpdateTimezoneResult = new CalendarInviteBase.UpdateTimezoneResult(testUpdateTimezoneInput);
            
            CalendarInviteBase.UpdateResponseInput testUpdateResponseInput = new CalendarInviteBase.UpdateResponseInput(testLoadResponseInput);
            CalendarInviteBase.UpdateResponseResult testUpdateResponseResult = new CalendarInviteBase.UpdateResponseResult(testUpdateResponseInput);
            
            CalendarInviteBase.AddInviteesInput testAddInviteesInput = new CalendarInviteBase.AddInviteesInput(testLoadResponseInput);
            CalendarInviteBase.InviteResult testInviteResult = new CalendarInviteBase.InviteResult(testAddInviteesInput);
            
            CalendarInviteBase.NewInvitee testNewInvitee = new CalendarInviteBase.NewInvitee();
            
            CalendarInviteBase.Respondent testRespondent1 = new CalendarInviteBase.Respondent();
            CalendarInviteBase.Respondent testRespondent2 = new CalendarInviteBase.Respondent();
            List<CalendarInviteBase.Respondent> testListRespondent = new List<CalendarInviteBase.Respondent>();
            testListRespondent.add(testRespondent1);
            testListRespondent.add(testRespondent2);
            testListRespondent.sort();
            System.Assert(testRespondent1.participant_status != '');
            
            CalendarInviteBase.EmailData ed = new CalendarInviteBase.EmailData();
            
            CalendarInviteBase.getResponseOptions();
            
            DateTime testDT1 = DateTime.now();
            DateTime testDT2 = CalendarInviteBase.adjustDate(testDT1, '2330');
            DateTime testDT3 = CalendarInviteBase.adjustDate(testDT2, '-2330');
            System.Assert(testDT1 == testDT3);
            
            boolean sameDay = CalendarInviteBase.isSameDay(testDT1, testDT2, '-0500');
            System.Assert(sameDay == false);
            
            sameDay = CalendarInviteBase.isSameDay(testDT1, testDT3, '-0500');
            System.Assert(sameDay == true);
            
            CalendarInviteBase.formatDate(testDT1, '-0500');
            CalendarInviteBase.formatTime(testDT1, '-0500');
            
            // SendEmail(Id invitee, Id eventInviteResponse, Id template, Id orgEmail, string subject, string body)
            // getEvent(Id eventId, Id eventInviteId, Id eventInviteResponseId)
            // CalculateLocation(Case c)
            // CalculateEndDate(Case c)
            // GetEmailDataFromEvent(Event e, Calendar_Invite__c settings)
            
        }
        catch (Exception e)
        {
            System.debug(' Exception Executing CalendarInvite Class Tests: ' + e.getMessage());
            throw e;
        }
        Test.stopTest();
    }
    
    static testMethod void testCreateUpdateInviteFromCase()
    {
        //return;
        Test.startTest();
        try
        {
            Profile p = getProfile('System Administrator');
            User u = createUser(p);
            insert u;
            Account a = createAccount();
            insert a;
            Contact c = createContact(u.Id, a.Id);
            c.email = 'test@test.com.fail';
            insert c;
            
            Case myCase = createCase(a.Id, 'Test 1', 'New');
            myCase.Invite_Date_Time__c = DateTime.now();
            myCase.ContactId = c.Id;
            insert myCase;
            
            ApexPages.StandardController stdC = new ApexPages.StandardController(myCase);
            CalendarInvitePages calInv = new CalendarInvitePages(stdC);
            calInv.SendCalendarInvite();
            
            // Do it twice to trigger event delete functionality
            stdC = new ApexPages.StandardController(myCase);
            calInv = new CalendarInvitePages(stdC);
            calInv.SendCalendarInvite();
            
            myCase.Invite_Date_Time__c = DateTime.now() + 1;
            update myCase;
            
            myCase = [SELECT Id, Event_Invite__c, Invite_Date_Time__c FROM Case WHERE Id = :myCase.Id];
            Event e = [SELECT Id, StartDateTime FROM Event WHERE Event_Invite__c = :myCase.Event_Invite__c];
            
            system.assert(myCase.Invite_Date_Time__c == e.StartDateTime);
        }
        catch (Exception e)
        {
            System.debug(' Exception Executing CalendarInvite Class Tests: ' + e.getMessage());
            throw e;
        }
        Test.stopTest();
    }
    
    static testMethod void testRemoteActions()
    {
        //return;
        try
        {
            Profile p = getProfile('System Administrator');
            User u = createUser(p);
            insert u;
            Account a = createAccount();
            insert a;
            Contact c = createContact(u.Id, a.Id);
            c.email = 'test@test.com.fail';
            insert c;
            
            Account v = createAccount();
            v.Name = 'Test Invite Destination';
            insert v;
            
            Case myCase = createCase(a.Id, 'Test 1', 'New');
            myCase.Invite_Date_Time__c = DateTime.now();
            myCase.ContactId = c.Id;
            myCase.Invite_Destination__c = v.Id;
            insert myCase;
            
            Test.startTest();
        
            ApexPages.StandardController stdC = new ApexPages.StandardController(myCase);
            CalendarInvitePages calInv = new CalendarInvitePages(stdC);
            calInv.SendCalendarInvite();
            
            
            EventInviteResponse__c eir = [SELECT Id, Event_Invite__c, Invitee__c, Invitee__r.Email FROM EventInviteResponse__c WHERE Invitee__r.Email = :c.email LIMIT 1];
            
            
            CalendarInviteBase.LoadResponseInput lri = new CalendarInviteBase.LoadResponseInput();
            lri.eirId = eir.Id;
            lri.eiId = eir.Event_Invite__c;
            lri.email = eir.Invitee__r.Email;
            string input = JSON.serialize(lri);
            CalendarInvite.LoadResponseDetail(input);
            
            
            CalendarInviteBase.UpdateTimezoneInput utzi = new CalendarInviteBase.UpdateTimezoneInput(lri);
            utzi.timezone = 'GMT+1400 (LINT)';
            input = JSON.serialize(utzi);
            CalendarInvite.UpdateTimezone(input);
            
            Contact invitee = [SELECT Id, Timezone__c FROM Contact WHERE id =: eir.Invitee__c LIMIT 1];
            system.assert(invitee.Timezone__c.startsWith('GMT+1400') && invitee.Timezone__c.endsWith('(LINT)'), 'Contact timezone not updated. Contact Timezone: ' + invitee.Timezone__c + ' should be : ' + utzi.timezone);
            
            // Negative test scenario
            utzi.timezone = 'GMT+1900 (FAKE)';
            input = JSON.serialize(utzi);
            CalendarInvite.UpdateTimezone(input);
            invitee = [SELECT Id, Timezone__c FROM Contact WHERE id =: eir.Invitee__c LIMIT 1];
            system.assert(invitee.Timezone__c.startsWith('GMT+1400') && invitee.Timezone__c.endsWith('(LINT)'), 'Contact timezone not updated. Contact Timezone: ' + invitee.Timezone__c + ' should be : ' + utzi.timezone);
            
            
            CalendarInviteBase.UpdateResponseInput uri = new CalendarInviteBase.UpdateResponseInput(lri);
            uri.response = 'Accepted';
            uri.note = 'Testing response update';
            input = JSON.serialize(uri);
            CalendarInvite.UpdateResponse(input);
            
            eir = [SELECT Id, Event_Invite__c, Invitee__c, Invitee__r.Email, Response__c, Response_Note__c FROM EventInviteResponse__c WHERE Invitee__r.Email = :c.email LIMIT 1];
            system.assert(eir.Response__c == uri.response && eir.Response_Note__c == uri.note, 'Response not updated');
            
            
            CalendarInviteBase.AddInviteesInput aii = new CalendarInviteBase.AddInviteesInput(lri);
            
            List<CalendarInviteBase.NewInvitee> nis = new List<CalendarInviteBase.NewInvitee>();
            CalendarInviteBase.NewInvitee ni = new CalendarInviteBase.NewInvitee();
            ni.email = 'test-event-invite-add-response@test.com';
            ni.firstname = 'firstname';
            ni.lastname = 'lastname';
            ni.company = 'test company';
            ni.title = 'test title';
            
            CalendarInviteBase.NewInvitee ni2 = new CalendarInviteBase.NewInvitee();
            ni2.email = 'test-event-invite-add-response-second@test.com';
            ni2.firstname = 'firstname2';
            ni2.lastname = 'lastname2';
            ni2.company = 'test company two';
            ni2.title = 'test title two';
            
            nis.add(ni);
            nis.add(ni2);
            
            aii.newinvitees = nis;
            input = JSON.serialize(aii);
            CalendarInvite.SendInvites(input);
            
            try
            {
                eir = [SELECT Id, Event_Invite__c, Invitee__c, Invitee__r.Email, Invitee__r.Company__c, Response__c, Response_Note__c FROM EventInviteResponse__c WHERE Invitee__r.Email = 'test-event-invite-add-response@test.com' LIMIT 1];
                system.assert(eir.Id != null && eir.Invitee__r.Company__c == ni.company, 'Something is wrong with adding new invitees');
            }
            catch (DMLException ex)
            {
                system.debug('Error encountered when attempting to find new invitee record: ' + ex.getMessage());
                throw ex;
            }
            
            
            Test.stopTest();
            
        }
        catch (Exception e)
        {
            System.debug(' Exception Executing CalendarInvite Class Tests: ' + e.getMessage());
            throw e;
        }
    }
    
    static testMethod void testPageController()
    {
        //return;
        try
        {
            Profile p = getProfile('System Administrator');
            User u = createUser(p);
            insert u;
            Account a = createAccount();
            insert a;
            Contact c = createContact(u.Id, a.Id);
            c.email = 'test@test.com.fail';
            insert c;
            
            Account v = createAccount();
            v.Name = 'Test Invite Destination';
            insert v;
            
            Case myCase = createCase(a.Id, 'Test 1', 'New');
            myCase.Invite_Date_Time__c = DateTime.now();
            myCase.ContactId = c.Id;
            myCase.Invite_Destination__c = v.Id;
            insert myCase;
            
            ApexPages.StandardController stdC = new ApexPages.StandardController(myCase);
            CalendarInvitePages calInv = new CalendarInvitePages(stdC);
            calInv.SendCalendarInvite();
            
            
            EventInviteResponse__c eir = [SELECT Id, Event_Invite__c, Invitee__c, Invitee__r.Email FROM EventInviteResponse__c WHERE Invitee__r.Email = :c.email LIMIT 1];
            
            
            CalendarInviteBase.LoadResponseInput lri = new CalendarInviteBase.LoadResponseInput();
            lri.eirId = eir.Id;
            lri.eiId = eir.Event_Invite__c;
            lri.email = eir.Invitee__r.Email;
            CalendarInviteBase.AddInviteesInput aii = new CalendarInviteBase.AddInviteesInput(lri);
            
            List<CalendarInviteBase.NewInvitee> nis = new List<CalendarInviteBase.NewInvitee>();
            CalendarInviteBase.NewInvitee ni = new CalendarInviteBase.NewInvitee();
            ni.email = 'test-event-invite-add-response@test.com';
            ni.firstname = 'firstname';
            ni.lastname = 'lastname';
            ni.company = 'test company';
            ni.title = 'test title';
            
            CalendarInviteBase.NewInvitee ni2 = new CalendarInviteBase.NewInvitee();
            ni2.email = 'test-event-invite-add-response-second@test.com';
            ni2.firstname = 'firstname2';
            ni2.lastname = 'lastname2';
            ni2.company = 'test company two';
            ni2.title = 'test title two';
            
            nis.add(ni);
            nis.add(ni2);
            
            aii.newinvitees = nis;
            string input = JSON.serialize(aii);
            CalendarInvite.SendInvites(input);
            
            Test.startTest();
            
            stdC = new ApexPages.StandardController(eir);
            CalendarInvitePages cI_e = new CalendarInvitePages(stdC);
            cI_e.ResendInvite();
            cI_e.CancelInvite();
            
            EventInvite__c ei = [SELECT Id FROM EventInvite__c WHERE Id =: eir.Event_Invite__c];
            stdC = new ApexPages.StandardController(ei);
            cI_e = new CalendarInvitePages(stdC);
            cI_e.ResendInvites();
            cI_e.CancelInvites();
            
            Test.stopTest();
            
        }
        catch (Exception e)
        {
            System.debug(' Exception Executing CalendarInvite Class Tests: ' + e.getMessage());
            throw e;
        }
    }
    
    /*
     * Create a basic User sObject
     */
    public static User createUser(Profile profile) {
        return createUser(profile, 'testuser@place.com.usertest');
    }
    
    /*
     * Create a basic User sObject with a specified Username
     */
    public static User createUser(Profile profile, String username) {
        return new User(
            ProfileId = profile.Id,
            Username = username,
            IsActive = true,
            Alias = 'testuser',
            Email = 'testuser@place.com.usertest',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_CA',
            TimeZoneSidKey = 'America/New_York'
        );
    }
    
    /*
     * Create a list of basic User sObjects
     */
    public static List<User> createUserList(Integer numUsers) {
        List<User> userList = new List<User>();
        for (Integer i = 0; i < numUsers; i++) {
            String username = 'testuser' + i + '@place.com.usertest';
            userList.add(createUser(getProfile(), username));
        }
        return userList;
    }
    
    /*
     * Create a basic Account sObject
     */
    public static Account createAccount() {
        return new Account(
            AccountNumber = '12345678',
            BillingCity = 'Toronto',
            BillingCountry = 'Canada',
            //BillingCountryCode = 'CA',
            //BillingStateCode = 'ON',
            BillingPostalCode = 'M5J 2V5',
            BillingStreet = '25 York Street',
            Description = 'A test account',
            Industry = 'Technology',
            Name = 'Test Account',
            ShippingCity = 'Toronto',
            ShippingCountry = 'Canada',
            //ShippingCountryCode = 'CA',
            //ShippingStateCode = 'ON',
            ShippingPostalCode = 'M5J 2V5',
            ShippingStreet = '25 York Street'
        );
    }

    /*
     * Create a basic Lead sObject
     */
    public static Lead createLead() {
        return new Lead(
            FirstName = 'Lead',
            LastName = 'Test',
            Company = 'My Test Company',
            //Status = 'Qualified',
            Status = 'New',
            City = 'Toronto', 
            Country = 'Canada',
            //CurrencyIsoCode = 'CAD',
            Email = 'lead.test@email.com',
            PostalCode = 'M5J 2V5',
            Street = '25 York Street',
            Industry = 'Technology'
        );
    }
    
    /*
     * Create a basic Lead object with an owner.
     * @param   userId      the ID of the user to set as the owner of the Lead
     * @return              a Lead sObject
     */
    public static Lead createLead(Id userId) {
        Lead lead = createLead();
        // Set the owner of the Lead
        lead.OwnerId = userId;
        return lead;
    }
    
    /**
      * Create an opportuntiy with an owner and related to an account
      * @param userId the user who will be the opportunity owner
      * @param accountId the account that will be associated to the opportunity
      */
    public static Opportunity createOpportunity(Id userId, Id accountId) {
        return new Opportunity (
            OwnerId = userId,
            Name = 'Opp',
            AccountId = accountId,
            CloseDate = (Date.Today()).addDays(30),
            StageName = 'Qualify',
            type='New Business'
        );
    }
    
    /**
      * Create a contact with an owner and related to an account
      * @param  userId      the owner of the contact
      * @param  accountId   the account associated with this contact
      */
    public static Contact createContact(Id userId, Id accountId) {
        return new Contact(
            OwnerId = userId,
            AccountId = accountId,
            FirstName = 'Contact',
            LastName = 'Test',
            Title = 'Test Contact'
        );
    }
    
    /**
      * Create a basic Task 
      */
    public static Task createTask(String subject, String status, String description) {
        return new Task(
            Description = description,
            Status = status,
            Subject = subject
        );
    }
    
    /**
      * Create a basic Task sObject linked to an sObject via whoId (Lead, Contact, etc.) or whatId (Account, Opportunity, etc.)
      */
    public static Task createTask(Id whatId, Id whoId, String subject, String status, String description) {
        Task task = createTask(subject, status, description);
        task.WhatId = whatId;
        task.WhoId = whoId;
        return task;
    }
    
    /**
      * Create a basic Task sObject linked to an sObject via whoId (Lead, Contact, etc.) or whatId (Account, Opportunity, etc.)
      */
    public static Task createTask(Id whatId, Id whoId) {
        Task task = createTask('Test Subject', 'Not Started', 'Test Task Description');
        task.WhatId = whatId;
        task.WhoId = whoId;
        return task;
    }
    
    /**
      * Create a basic Case sObject linked to an Account
      */
    public static Case createCase(Id accountId, String subject, String status) {
        return new Case(
            AccountId = accountId,
            Status = status,
            Subject = subject
        );
    }
    
    /*
     * Get a User sObject based on Id.
     *
     * @param   userId      specify the ID of the user to retrieve
     * @return              a User sObject
     */
    public static User getUserById(Id userId) {
        System.debug('User ID: ' + userId);
        return [SELECT Id,
        ProfileId,
        Username,
        Alias,
        FirstName,
        LastName
        FROM User 
        WHERE Id = :userId];
    }   

    /*
     * Retrieve a Profile sObject
     *
     * @return      a Profile sObject
     */
    public static Profile getProfile() {
        for (Profile p : [SELECT Id, PermissionsModifyAllData, Name FROM Profile]) {
            if (p.PermissionsModifyAllData) {
                return p;
            }
        }
        
        return new Profile();
    }
    
    /*
     * Retrieve a Profile sObject based on Name
     *
     * @param   name    the name of the profile to retrieve
     * @return          a Profile sObject
     */
    public static Profile getProfile(String name) {
        return [SELECT Id, Name FROM Profile WHERE Name = :name];
    }
    
    /*
     * Retrieve an Account sObject
     *
     * @param   id  the id of the Account sObject to retrieve
     * @return      the Account sObject
     */
    public static Account getAccount(Id id) {
        return [SELECT Id, 
        OwnerId,
        AccountNumber
        FROM Account WHERE Id = :id];
    }

    /*
     * Retrieve a Map of Account sObjects
     *
     * @param   ids the list of ids of the Account sObjects to retrieve
     * @return      a Map of Account sObjects
     */
    public static Map<Id, Account> getAccountMap(List<Id> ids) {
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (Account a : [SELECT Id, 
                          OwnerId,
                          AccountNumber,
                          //CurrencyIsoCode,
                          ShippingCity,
                          ShippingCountry,
                          //ShippingCountryCode,
                          ShippingLatitude,
                          ShippingLongitude,
                          ShippingPostalCode,
                          ShippingState,
                          //ShippingStateCode,
                          ShippingStreet,
                          BillingCity,
                          BillingCountry,
                          //BillingCountryCode,
                          BillingLatitude,
                          BillingLongitude,
                          BillingPostalCode,
                          BillingState,
                          //BillingStateCode,
                          BillingStreet
                          FROM Account 
                          WHERE Id IN :ids]) {
            accountMap.put(a.Id, a);
        }
        return accountMap;
    }
        
    /*
     * Retrieve a Lead sObject
     *
     * @param   id  the id of the Lead sObject to retrieve
     * @return      the Lead sObject
     */
    public static Lead getLead(Id id) {
        List<Lead> leadList = [SELECT Id, 
                                OwnerId
                                FROM Lead WHERE Id = :id];
        if (leadList.size() > 0) {
            return leadList[0];
        } else {
            return null;
        }
    }
    
    /**
      * Retrieve an Opportunity sObject
      *
      * @param id the id of the Opportuntiy to retrive
      * @return The opportunity object
      */
    public static Opportunity getOpportunity(Id id) {
        return [SELECT Id,
                       Amount,
                       ContractId,
                       //CurrencyIsoCode,
                       Name,
                       //RecordTypeId,
                       StageName,
                       Type   
                FROM Opportunity
                WHERE Id = :id];
    }

    public static Task getTask(Id id) {
        return [SELECT  Id,
                        CreatedDate
                FROM Task
                WHERE Id = :id
                LIMIT 1];
    }

    /**
      * SF-534: Retrieve a Task by WhoId
      */
    public static Task getTaskByWhoId(Id whoId) {
        List<Task> taskList = [SELECT Id
                               FROM Task
                               WHERE WhoId = :whoId];
        if((null != taskList) && (taskList.size() == 1)) {
            return taskList[0];
        }   else {
            return null;
        }
    }

    /**
      * SF-534: Retrieve a Record Type by Developer Name and SObject
      */
    public static RecordType getRTbyDevName(String devName, String sObjName) {
        List<RecordType> rtList = [SELECT Id, Name
                                   FROM RecordType
                                   WHERE DeveloperName = :devName AND SobjectType = :sObjName];
        if((null != rtList) && (rtList.size() == 1)) {
            return rtList[0];
        }   else {
            return null;
        }
    }
    
    /**
      * SF-597: Retrieve list of Tasks by WhatId
      */
    public static List<Task> getTasksByWhatId(Id whatId) {
        List<Task> taskList = [SELECT 
                                    Id,
                                    Description,
                                    Status,
                                    Subject,
                                    WhatId
                               FROM Task
                               WHERE WhatId = :whatId];
        if (taskList.size() > 0) {
            return taskList;
        } else {
            return null;
        }
    }

    public static Task getTaskByWhatId(Id whatId) {
        List<Task> taskList = getTasksByWhatId(whatId);
        if (taskList != null) {
            return taskList[0];
        } else {
            return null;
        }
    }

    /**
      * Retrieve a Case sObject by ID.
      */
    public static Case getCase(Id caseId) {
        List<Case> caseList = getCase(new List<Id>{caseId});
        if(caseList != null && caseList.size() == 1) {
            return caseList[0];
        }   else {
            return null;
        }
    }

    /**
      * Retrieve a List of Case sObject by ID.
      */
    public static List<Case> getCase(List<Id> caseIdList) {
        List<Case> caseList = [ SELECT  Id,
                                        Status,
                                        CaseNumber
                                FROM Case
                                WHERE Id IN :caseIdList];
        return caseList;
    }
        
}