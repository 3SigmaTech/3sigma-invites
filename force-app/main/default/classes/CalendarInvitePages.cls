global class CalendarInvitePages extends CalendarInviteBase
{
  global CalendarInvitePages(ApexPages.StandardController stdC)
  {
    settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
    myEvent = new Event();
    
    try
    {
      myCase = [SELECT Id, Subject, Description, ContactId
                     , Event_Invite__c, Invite_Date_Time__c, Invite_End_Date_Time__c
                     , Invite_Destination__r.Name, Invite_Destination__r.BillingAddress
                  FROM Case
                 WHERE Id =: stdC.getId()
                 LIMIT 1
               ];
      
      myEvent.RecordTypeId = settings.Event_Record_ID__c;
      myEvent.Subject = myCase.Subject;
      myEvent.Description = myCase.Description;
      myEvent.Location = CalculateLocation(myCase);
      myEvent.StartDateTime = myCase.Invite_Date_Time__c;
      myEvent.EndDateTime = CalculateEndDate(myCase);
      myEvent.WhoId = myCase.ContactId;
      myEvent.WhatId = myCase.Id;

      myEvent.Event_Organizer__c = settings.Default_Org_Wide_Sender__c;
      myEvent.Event_Invite_Template__c = settings.Default_Email_Template__c;

      myEvent.Invite_Email_Subject__c = settings.Default_Subject__c;
      myEvent.Invite_Email_Body__c = settings.Default_Description__c;

      myObjectType = 'case';
    }
    catch(Exception e){}
    try
    {
      myContact = (Contact)stdC.getRecord();
      myObjectType = 'contact';
    }
    catch(Exception e){}
    try
    {
        myEventInviteResponse = (EventInviteResponse__c)stdC.getRecord();
        myObjectType = 'eventinviteresponse';
    }
    catch(Exception e){}
    try
    {
        myEventInvite = (EventInvite__c)stdC.getRecord();
        myObjectType = 'eventinvite';
    }
    catch(Exception e){}
  }
  global CalendarInvitePages() {}
  
  public InviteResponse ResponseDetails
  {
      get
      {
        LoadResponseInput inputs = new LoadResponseInput();
        inputs.eirId = eirId;
        
        CalendarInvite calInv = new CalendarInvite();
        return calInv.LoadResponseDetailInner(inputs);
      }
      set;
  }
  
  public PageReference SendCalendarInvite()
  {
    if (myObjectType == 'case')
    {
      // First delete existing calendar invite
      if (myCase.Event_Invite__c != null)
      {
        Event myE = getEvent(null, myCase.Event_Invite__c, null);
        List<EventInviteResponse__c> myEIRs = [SELECT Id FROM EventInviteResponse__c WHERE event_invite__c =: myCase.Event_Invite__c];
        
        for (EventInviteResponse__c eir : myEIRs)
        {
          delete eir;
        }
        //delete myEI;
        Database.delete(myCase.Event_Invite__c);
        delete myE;
      }
      insert myEvent;
    }

    return null;
  }
  
  public PageReference ResendInvite() // Called from Event Invite Response for resending invite email
  {
      Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
      
      Event e = getEvent(null, myEventInviteResponse.event_invite__c, null);
      
      EmailData myData = GetEmailDataFromEvent(e, settings);
      
      SendEmail(myEventInviteResponse.invitee__c, myEventInviteResponse.Id, myData.EmailTemplateId, myData.OrgWideEmailAddressId, 'Reminder: ' + e.invite_email_subject__c, e.invite_email_body__c);
      
      PageReference eirPage = new PageReference('/' + myEventInviteResponse.id);
      eirPage.setRedirect(true);
      return eirPage;
  }
  
  public PageReference ResendInvites() // Called from Event Invite (or Case) for resending invite emails to all invitees
  { 
      Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
      
      Id eiId;
      Boolean redir = false;
      
      if (myEventInvite == null)
      {
          eiId = myCase.Event_Invite__c;
      }
      else
      {
          eiId = myEventInvite.Id;
          redir = true;
      }
      
      Event e = getEvent(null, eiId, null);
      
      List<EventInviteResponse__c> eirs = [SELECT Id, Invite_Source__c, event_invite__c, invitee__c 
                                             FROM EventInviteResponse__c 
                                            WHERE Event_Invite__c =: eiId
                                              AND Response__c <> 'Canceled'
                                          ];
      
      EmailData myData = GetEmailDataFromEvent(e, settings);
      
      for (EventInviteResponse__c eir : eirs)
      {
          SendEmail(eir.invitee__c, eir.Id, myData.EmailTemplateId, myData.OrgWideEmailAddressId, 'Reminder: ' + e.invite_email_subject__c, e.invite_email_body__c);
      }
      
      if (redir)
      {
          PageReference eiPage = new PageReference('/' + eiId);
          eiPage.setRedirect(true);
          return eiPage;
      }
      return null;
  }
  
  public PageReference CancelInvite() // Called from Event Invite Response for sending cancel invite email
  {
      Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
      
      Event e = getEvent(null, myEventInviteResponse.event_invite__c, null);
      myEventInviteResponse.response__c = 'Canceled';
      myEventInviteResponse.response_date__c = DateTime.Now();
      update myEventInviteResponse;
      
      EmailData myData = GetEmailDataFromEvent(e, settings);
      
      SendEmail(myEventInviteResponse.invitee__c, myEventInviteResponse.Id, myData.EmailTemplateId, myData.OrgWideEmailAddressId, 'Canceled: ' + e.invite_email_subject__c, e.invite_email_body__c);
      
      PageReference eirPage = new PageReference('/' + myEventInviteResponse.id);
      eirPage.setRedirect(true);
      return eirPage;
  }
  
  public PageReference CancelInvites() // Called from Event Invite for sending cancel invite emails to all invitees
  { 
      Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
      
      Event e = getEvent(null, myEventInvite.Id, null);
      
      List<EventInviteResponse__c> eirs = [SELECT Id, Invite_Source__c, event_invite__c, invitee__c 
                                             FROM EventInviteResponse__c 
                                            WHERE Event_Invite__c =: myEventInvite.Id
                                              AND Response__c <> 'Canceled'
                                          ];
      myEventInvite.Status__c = 'Canceled';
      
      EmailData myData = GetEmailDataFromEvent(e, settings);
      
      for (EventInviteResponse__c eir : eirs)
      {
          eir.response__c = 'Canceled';
          eir.response_date__c = DateTime.Now();
          update eir;
          SendEmail(eir.invitee__c, eir.Id, myData.EmailTemplateId, myData.OrgWideEmailAddressId, 'Canceled: ' + e.invite_email_subject__c, e.invite_email_body__c);
      }
      
      PageReference eiPage = new PageReference('/' + myEventInvite.id);
      eiPage.setRedirect(true);
      return eiPage;
  }
  
}