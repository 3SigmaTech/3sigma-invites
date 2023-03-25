global class CalendarInvite extends CalendarInviteBase
{
  global CalendarInvite(ApexPages.StandardController stdC) {}
  global CalendarInvite() {}


  @RemoteAction
  global static string LoadResponseDetail(string input)
  {
    LoadResponseInput inputs = (LoadResponseInput)JSON.deserialize(input, LoadResponseInput.class);
    CalendarInvite calInv = new CalendarInvite();
    return JSON.serialize(calInv.LoadResponseDetailInner(inputs));
  }
  
  public InviteResponse ResponseDetails
  {
      get { return (new CalendarInvitePages()).ResponseDetails; }
      set;
  }
  
  
  public InviteResponse LoadResponseDetailInner(LoadResponseInput inputs)
  {
    Event e = null;
    List<EventInviteResponse__c> eirList = new List<EventInviteResponse__c>();
    
    if (inputs.eiId == null || inputs.eiId == '')
    {
        EventInviteResponse__c myeir = null;
        try {
            myeir = [SELECT Id, Event_Invite__c, Invitee__r.Email FROM EventInviteResponse__c WHERE Id = :inputs.eirId];
            inputs.eiId = myeir.Event_Invite__c;
            inputs.email = myeir.Invitee__r.Email;
        } catch (Exception ex) {
            // Eat; handled below
        }
    }
        
    try {
        e = getEvent(null, inputs.eiId, null);
        eirList = [SELECT Id, Event_Invite__c, Response__c, Response_Date__c, Response_Note__c, Invite_URL__c
                        , Invitee__r.FirstName, Invitee__r.LastName, Invitee__r.Email, Invitee__r.Merged_Timezone__c
                     FROM EventInviteResponse__c 
                    WHERE Event_Invite__c = :inputs.eiId
                      AND (Response__c <> 'Canceled' OR Id =: inputs.eirId)
                  ];
    } catch (Exception ex)  {
        // Eat; handled below
    }
    
    // Add inputs to return value
    InviteResponse rv = new InviteResponse(inputs);
    if (e == null || eirList == null || eirList.size() == 0)
    {
      rv.success = false;
      return rv;
    }
    
    // Add event details to return value
    rv.subject = e.subject;
    rv.description = e.description;
    rv.location = e.location;
    rv.startdt = e.StartDateTime;
    rv.enddt = e.EndDateTime;

    
    Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
    EmailData myData = GetEmailDataFromEvent(e, settings);
    rv.organizer = myData.organizer;
    rv.organizer_email = myData.organizer_email;
    
    rv.company_name = settings.Company_Name__c;
    rv.company_website = settings.Company_Website__c;
    
    String inviteSite = settings.Site_URL__c;
    if (inviteSite == '' || inviteSite == null)
    {
      inviteSite = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    rv.detailURL = inviteSite + '?eirId=' + string.valueOf(inputs.eirId);

    
    // Add invitee details to return value
    integer maxN = eirList.size();
    boolean foundMine = false;
    String tzval = '';
    for (integer ndx = 0; ndx < maxN; ndx++)
    {
      EventInviteResponse__c eir = eirList.get(ndx);
      
      Respondent r = new Respondent();
      
      r.isMe = (eir.Invitee__r.email == inputs.email);
      r.firstname = eir.Invitee__r.FirstName;
      r.lastname = eir.Invitee__r.LastName;
      r.response = eir.Response__c;
      r.email = eir.Invitee__r.Email;
      r.responsedate = (eir.Response_Date__c != null ? eir.Response_Date__c : DateTime.Now());
      r.responsenote = eir.Response_Note__c;
      
      if (r.isMe)
      {
        foundMine = true;
        rv.timezone = eir.Invitee__r.Merged_Timezone__c;
        rv.timezoneshort = rv.timezone.split('\\ ')[0]
                         + rv.timezone.substring(rv.timezone.lastIndexOf('(') - 1);
        //rv.detailURL = eir.Invite_URL__c; // did not return a value for whatever reason
        rv.status = (eir.Response__c == 'Canceled' ? 'CANCELLED' : 'CONFIRMED');
        rv.method = (eir.Response__c == 'Canceled' ? 'CANCEL' : 'REQUEST');
      
        tzval = rv.timezone.split('\\ ')[0].replace('GMT','').replace('+','');
      }
      
      rv.respondents.add(r);
    }
    
    // If we cannot find the requester's record then we return nothing
    if (foundMine == false)
    {
      return new InviteResponse(inputs);
    }
    
    // Set from/to datetime string
    if (isSameDay(rv.startdt, rv.enddt, tzval))
    {
      rv.dateTimeString = formatDate(rv.startdt, tzval)
                        + ' - '
                        + formatTime(rv.enddt, tzval);
    }
    else
    {
      rv.dateTimeString = formatDate(rv.startdt, tzval)
                        + ' - '
                        + formatDate(rv.enddt, tzval);
    }
    rv.startdtStr = rv.startdt.formatGMT('yyyyMMdd\'T\'HHmmss');
    rv.enddtStr = rv.enddt.formatGMT('yyyyMMdd\'T\'HHmmss');
    
    rv.nowStr = DateTime.Now().formatGMT('yyyyMMdd\'T\'HHmmss');
    
    // update Response Dates
    for (integer ndx = 0; ndx < maxN; ndx++)
    {
      Respondent r = rv.respondents.get(ndx);
      r.responsedateString = formatDate(r.responsedate, tzval);
    }

    rv.respondents.sort();
    return rv;
  }

  @RemoteAction
  global static String UpdateTimezone(string input)
  {
    UpdateTimezoneInput inputs = (UpdateTimezoneInput)JSON.deserialize(input, UpdateTimezoneInput.class);
    
    EventInviteResponse__c eir = [SELECT Id, Event_Invite__c, Response__c
                                       , Response_Date__c, Response_Note__c, Invitee__r.Email, Invitee__c
                                    FROM EventInviteResponse__c WHERE Id =: inputs.inputs.eirId LIMIT 1];
    
    UpdateTimezoneResult rv = new UpdateTimezoneResult(inputs);
    if (eir == null)
    {
      return JSON.serialize(rv);
    }
    
    string tzstart = inputs.timezone.split(' ')[0];
    string tzend = inputs.timezone.split(' ')[1];
    
    // TODO: Replace looking up against the field with looking up against the metadata
    
    List<Schema.PicklistEntry> ples = Schema.getGlobalDescribe().get('contact')
                                        .getDescribe().fields.getMap().get('x3st_invites__Timezone__c')
                                        .getDescribe().getPicklistValues();
    
    for (PickListEntry ple : ples)
    {
      string comptz = ple.getValue(); // getLabel();
      if (comptz.startsWith(tzstart) && comptz.endsWith(tzend))
      {
        try
        {
          Contact c = [SELECT id, Timezone__c FROM Contact WHERE id =: eir.Invitee__c LIMIT 1];
          c.Timezone__c = comptz;
          update c;
          rv.success = true;

          return JSON.serialize(rv);
        }
        catch (Exception ex)
        {
          rv.error = ex.getMessage();
          system.debug(ex.getMessage());
        }
      }
    }
    if (rv.error == '')
    {
        rv.error = 'Timezone entry was not found!';
    }
    rv.success = false;

    return JSON.serialize(rv);
  }

  @RemoteAction
  global static String UpdateResponse(string input)
  {
    CalendarInvite calInv = new CalendarInvite();
    UpdateResponseInput inputs = (UpdateResponseInput)JSON.deserialize(input, UpdateResponseInput.class);

    EventInviteResponse__c eir = [SELECT Id, Event_Invite__c, Response__c
                                       , Response_Date__c, Response_Note__c, Invitee__r.Email
                                    FROM EventInviteResponse__c WHERE Id =: inputs.inputs.eirId LIMIT 1];

    UpdateResponseResult rv = new UpdateResponseResult(inputs);
    if (eir == null)
    {
      return JSON.serialize(rv);
    }

    Set<String> validResponses = CalendarInviteBase.getResponseOptions();
    if (!validResponses.contains(inputs.response))
    {
      rv.error = 'Invalid response';
      return JSON.serialize(rv);
    }

    eir.Response__c = inputs.response;
    eir.Response_Note__c = inputs.note;
    eir.Response_Date__c = DateTime.Now();
    try
    {
      update eir;
      return LoadResponseDetail(JSON.serialize(inputs.inputs));
    }
    catch (Exception ex)
    {
      rv.error = ex.getMessage();
    }

    return JSON.serialize(rv);

  }

  @RemoteAction
  global static String SendInvites(string input)
  {
    AddInviteesInput inputs = (AddInviteesInput)JSON.deserialize(input, AddInviteesInput.class);

    EventInviteResponse__c eir = [SELECT Id, Event_Invite__c, Response__c
                                       , Response_Date__c, Response_Note__c, Invitee__r.Id, Invitee__r.Email
                                    FROM EventInviteResponse__c WHERE Id =: inputs.inputs.eirId LIMIT 1];

    InviteResult rv = new InviteResult(inputs);
    if (eir == null)
    {
      return JSON.serialize(rv);
    }

    Contact inviter = [SELECT Id, AccountId FROM Contact WHERE Id =: eir.Invitee__r.Id];

    integer numNew = inputs.newinvitees.size();
    List<EventInviteResponse__c> neirList = new List<EventInviteResponse__c>();
    for (integer ndx = 0; ndx < numNew; ndx++)
    {
      NewInvitee ni = inputs.newinvitees.get(ndx);

      List<Contact> ncList = [SELECT Id, FirstName, LastName, email, title, Company__c, Account.Name FROM Contact WHERE email =: ni.email];
      Contact nc;

      if (ncList.size() == 0)
      {
        nc = new Contact(
          FirstName = ni.FirstName,
          LastName = ni.LastName,
          Email = ni.Email,
          Title = ni.Title,
          Company__c = ni.Company,
          AccountId = inviter.AccountId,
          Contact_Type__c = 'Invite Attendee'
        );
        insert nc;
      }
      /*
      else
      {
        nc = ncList.get(0);
        if (nc.FirstName != ni.FirstName)
        {
          // What to do?
        }
        if (nc.LastName != ni.LastName)
        {
          // What to do?
        }
        if (nc.Title != ni.Title)
        {
          // What to do?
        }
        if (nc.Account.Name != ni.Company)
        {
          // What to do?
        }
      }
      */
      
      EventInviteResponse__c neir = new EventInviteResponse__c (
        event_invite__c = eir.event_invite__c,
        Invite_Source__c = 'Added Via Invite',
        invitee__c = nc.Id
      );
      neirList.add(neir);
    }
    
    try
    {
      insert neirList;
      rv.error = '';
      rv.success = true;
    }
    catch (Exception ex)
    {
      rv.error = ex.getMessage();
    }

    return JSON.serialize(rv);
  }

}