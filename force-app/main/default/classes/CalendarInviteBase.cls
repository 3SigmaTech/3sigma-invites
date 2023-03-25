global virtual class CalendarInviteBase
{
  public EmailTemplate defaultEmailTemplate {get; set; }
  public OrgWideEmailAddress defaultOrgWideEmailAddress { get; set; }
    
  protected final Case myCase {get; set;}
  protected final Contact myContact {get; set;}
  protected final EventInviteResponse__c myEventInviteResponse {get; set;}
  protected final EventInvite__c myEventInvite {get; set;}

  public string myObjectType {get; set;}
  public Event myEvent {get; set;}
  public Calendar_Invite__c settings {get; set;}

  public string eiId {get; set;}
  public string eirId {get; set;}
  public string email {get; set;}
  public boolean isEmail {get; set;}

  public class inviteException extends Exception {}
  
  public class LoadResponseInput
  {
    public string eirId {get; set;}
    public string eiId {get; set;}
    public string email {get; set;}

    public LoadResponseInput()
    {
      eirId = '';
      eiId = '';
      email = '';
    }
  }

  public class InviteResponse
  {
    public LoadResponseInput inputs {get; set;}
    public string description {get; set;}
    public string subject {get; set;}
    public string location {get; set;}
    public DateTime startdt {get; set;}
    public DateTime enddt {get; set;}
    public List<Respondent> respondents {get; set;}
    public string detailURL {get; set;}
    public string dateTimeString {get; set;}
    public string startdtStr {get; set;}
    public string enddtStr {get; set;}
    public string nowStr {get; set;}
    public string timezone {get; set;}
    public string timezoneshort {get; set;}
    public boolean success {get; set;}
    public string organizer {get; set;}
    public string organizer_email {get; set;}
    public string method {get; set;}
    public string status {get; set;}
    public string company_name {get; set;}
    public string company_website {get; set;}
    
    public InviteResponse(LoadResponseInput passedInputs)
    {
      inputs = passedInputs;
      description = '';
      subject = '';
      location = '';
      startdt = null;
      enddt = null;
      respondents = new List<Respondent>();
      detailURL = '';
      dateTimeString = '';
      startdtStr = '';
      enddtStr = '';
      nowStr = '';
      timezone = '';
      timezoneshort = '';
      success = true;
      organizer = '';
      organizer_email = '';
      method = 'REQUEST';
      status = 'CONFIRMED';
      company_name = '';
      company_website = '';
    }
  }

  public class UpdateTimezoneInput
  {
    public LoadResponseInput inputs {get; set;}
    public String timezone {get; set;}

    public UpdateTimezoneInput(LoadResponseInput passedInputs)
    {
      inputs = passedInputs;
      timezone = '';
    }
  }

  public class UpdateTimezoneResult
  {
    public UpdateTimezoneInput inputs {get; set;}
    public boolean success {get; set;}
    public string error {get; set;}

    public UpdateTimezoneResult(UpdateTimezoneInput passedInputs)
    {
      inputs = passedInputs;
      success = false;
      error = '';
    }
  }

  public class UpdateResponseInput
  {
    public LoadResponseInput inputs {get; set;}
    public String response {get; set;}
    public String note {get; set;}

    public UpdateResponseInput(LoadResponseInput passedInputs)
    {
      inputs = passedInputs;
      response = '';
      note = '';
    }
  }

  public class UpdateResponseResult
  {
    public UpdateResponseInput inputs {get; set;}
    public boolean success {get; set;}
    public string error {get; set;}

    public UpdateResponseResult(UpdateResponseInput passedInputs)
    {
      inputs = passedInputs;
      success = false;
      error = 'Invalid inputs';
    }
  }

  public class AddInviteesInput
  {
    public LoadResponseInput inputs {get; set;}
    public List<NewInvitee> newinvitees {get; set;}

    public AddInviteesInput(LoadResponseInput passedInputs)
    {
      inputs = passedInputs;
      newinvitees = new List<NewInvitee>();
    }
  }

  public class InviteResult
  {
    public AddInviteesInput inputs {get; set;}
    public boolean success {get; set;}
    public string error {get; set;}

    public InviteResult(AddInviteesInput passedInputs)
    {
      inputs = passedInputs;
      success = false;
      error = 'Invalid inputs';
    }
  }

  public class NewInvitee
  {
    public string email {get; set;}
    public string firstname {get; set;}
    public string lastname {get; set;}
    public string company {get; set;}
    public string title {get; set;}

    public NewInvitee()
    {
      email = '';
      firstname = '';
      lastname = '';
      company = '';
      title = '';
    }
  } // NewInvitee

  public class Respondent implements Comparable
  {
    public boolean isMe {get; set;}
    public string firstname {get; set;}
    public string lastname {get; set;}
    public string email {get; set;}
    public string response {get; set;}
    public string participant_status 
    {
        get
        {
            if (this.response == 'Accepted')
            {
                return 'ACCEPTED';
            }
            else if (this.response == 'Declined')
            {
                return 'DECLINED';
            }
            else if (this.response == 'Undecided')
            {
                return 'TENTATIVE';
            }
            else //if (this.response == 'Not Responded')
            {
                return 'NEEDS-ACTION';
            }
        }
    }
    public DateTime responsedate {get; set;}
    public string responsedateString {get; set;}
    public string responsenote {get; set;}

    public Respondent()
    {
      isMe = false;
      firstname = '';
      lastname = '';
      email = '';
      response = '';
      responsedate = null;
      responsedateString = '';
      responsenote = '';
    }

    public Integer compareTo(Object compareTo)
    {
      Respondent comp = (Respondent)compareTo;
      if (isMe == comp.isMe)
      {
        return 0;
      }
      if (isMe)
      {
        return -1;
      }
      return 1;
    }
  }

  public class EmailData
  {
      public Id EmailTemplateId { get; set; }
      public Id OrgWideEmailAddressId { get; set; }
      public string organizer { get; set; }
      public string organizer_email { get; set; }
      
      public EmailData()
      {
          EmailTemplateId = null;
          OrgWideEmailAddressId = null;
          organizer = '';
          organizer_email = '';
      }
  }

  public void SendEmail(Id invitee, Id eventInviteResponse, Id template, Id orgEmail, string subject, string body)
  {
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    if (template != null)
    {
        message = Messaging.renderStoredEmailTemplate(template, invitee, eventInviteResponse);
    }
    else
    {
        message.setTargetObjectId(invitee);
        message.setWhatId(eventInviteResponse);
        if (body != '') { message.setHtmlBody(body); }
    }
    
    if (subject != '') { message.setSubject(subject); }
    
    if (orgEmail != null)
    {
      message.setOrgWideEmailAddressId(orgEmail);
    }

    system.debug('invitee : ' + invitee);
    system.debug('eventInviteResponse : ' + eventInviteResponse);
    system.debug('template : ' + template);
    system.debug('orgEmail : ' + orgEmail);
    system.debug('subject : ' + subject);
    system.debug('body : ' + body);
    

    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
    Messaging.SendEmailResult[] results = null;
    
    try
    {
        results = Messaging.sendEmail(messages);
    }
    catch (Exception e)
    {
        system.debug('Email failed');
    }

    if (results != null && results.size() > 0 && results[0].success)
    {
        System.debug('The email was sent successfully.');
    }
    else if (results != null && results.size() > 0)
    {
        System.debug('The email failed to send: ' + results[0].errors[0].message);
    }
  }

  public static Set<String> getResponseOptions()
  {
    Set<String> rv = new Set<String>();
    Schema.DescribeFieldResult fieldResult = EventInviteResponse__c.Response__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry val : ple)
    {
      rv.add(val.getLabel());
    }
    return rv;
  }

  public static DateTime adjustDate(DateTime dt, String tz)
  {
    integer tzhr = 0;
    integer tzmin = 0;
    if (tz.length() == 4) // positive
    {
      tzhr = integer.valueOf( tz.substring(0,2) );
      tzmin = integer.valueOf( tz.substring(2) );
    }
    else // length 5, negative
    {
        tzhr = -1 * integer.valueOf( tz.substring(1,3) );
        tzmin = -1 * integer.valueOf( tz.substring(3) );
    }
    return dt.addHours(tzhr).addMinutes(tzmin);
  }

  public static boolean isSameDay(DateTime d1, DateTime d2, String tz)
  {
    if (adjustDate(d1, tz).day() == adjustDate(d2, tz).day())
    {
      return true;
    }
    else
    {
      return false;
    }
  }

  public static string formatDate(DateTime dt, String tz)
  {
    return adjustDate(dt, tz).formatGMT('EEEE, MMMM d, yyyy ') + formatTime(dt, tz);
  }

  public static string formatTime(DateTime dt, String tz)
  {
    return adjustDate(dt, tz).formatGMT('h:mma')
        .replace('AM','<span style="font-variant: small-caps">am</span>')
        .replace('PM','<span style="font-variant: small-caps">pm</span>');
  }
  
  public static Event getEvent(Id eventId, Id eventInviteId, Id eventInviteResponseId)
  {
      Event e = new Event();
        
      if (eventId != null)
      {
         e = [SELECT Id, OwnerId, RecordTypeId, WhoId, WhatId
                   , Subject, Description, Location, StartDateTime, EndDateTime
                   , Event_Invite__c, Event_Invite_Template__c, Event_Organizer__c 
                   , invite_email_subject__c, invite_email_body__c, Send_Invite_Update__c
                FROM Event 
               WHERE Id =: eventId
               LIMIT 1
             ];
      }
      else if (eventInviteId != null)
      {
         e = [SELECT Id, OwnerId, RecordTypeId
                   , Subject, Description, Location, StartDateTime, EndDateTime
                   , Event_Invite__c, Event_Invite_Template__c, Event_Organizer__c 
                   , invite_email_subject__c, invite_email_body__c, Send_Invite_Update__c
                FROM Event 
               WHERE Event_Invite__c =: eventInviteId
               LIMIT 1
             ];
      }
      return e;
  }
  /*
  public static List<Event> getEvents(List<Id> eventIds, List<Id> eventInviteIds, List<Id> eventInviteResponseIds)
  {
      List<Event> es = new List<Event>();
        
      if (eventIds != null)
      {
         es= [SELECT Id, OwnerId, RecordTypeId, WhoId, WhatId
                   , Subject, Description, Location, StartDateTime, EndDateTime
                   , Event_Invite__c, Event_Invite_Template__c, Event_Organizer__c 
                   , invite_email_subject__c, invite_email_body__c, Send_Invite_Update__c
                FROM Event 
               WHERE Id in :eventIds
             ];
      }
      else if (eventInviteIds != null)
      {
         es= [SELECT Id, OwnerId, RecordTypeId
                   , Subject, Description, Location, StartDateTime, EndDateTime
                   , Event_Invite__c, Event_Invite_Template__c, Event_Organizer__c 
                   , invite_email_subject__c, invite_email_body__c, Send_Invite_Update__c
                FROM Event 
               WHERE Event_Invite__c in :eventInviteIds
             ];
      }
      return es;
  }
  */
  
  public static string CalculateLocation(Case c)
  {
      string Location = c.Invite_Destination__r.Name;
      if (c.Invite_Destination__r.BillingAddress != null)
      {
          Location += ' (' 
                  + c.Invite_Destination__r.BillingAddress.getStreet()
                  + (c.Invite_Destination__r.BillingAddress.getCity() != null
                  ? ' ' + c.Invite_Destination__r.BillingAddress.getCity()
                  : '')
                  + (c.Invite_Destination__r.BillingAddress.getState() != null
                  ? ', ' + c.Invite_Destination__r.BillingAddress.getState()
                  : '')
                  //+ (c.Invite_Destination__r.BillingAddress.getCountry() != null
                  //? ', ' + c.Invite_Destination__r.BillingAddress.getCountry() 
                  //: '')
                  + ')';
      }
      return Location;
  }

  public static DateTime CalculateEndDate(Case c)
  {
      DateTime endDate = c.Invite_End_Date_Time__c != null ? c.Invite_End_Date_Time__c
                          : (c.Invite_Date_Time__c != null ? c.Invite_Date_Time__c.addMinutes(90) 
                          : null);
      return endDate;
  }
  
  public EmailData GetEmailDataFromEvent(Event e, Calendar_Invite__c settings)
  {
      String calInviteTemplate = settings.Default_Email_Template__c;
      String calInviteEmail = settings.Default_Org_Wide_Sender__c;
      
      if (this.defaultEmailTemplate == null)
      {
          List<EmailTemplate> templates = [SELECT id FROM EmailTemplate WHERE name =: calInviteTemplate LIMIT 1];
          if (templates.size() > 0)
          {
              this.defaultEmailTemplate = templates.get(0);
          }
          
      }
      if (this.defaultOrgWideEmailAddress == null)
      {
          List<OrgWideEmailAddress> addresses = [SELECT id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName =: calInviteEmail LIMIT 1];
          if (addresses.size() > 0)
          {
              this.defaultOrgWideEmailAddress = addresses.get(0);
          }
      }
      
      Id my_et_id = this.defaultEmailTemplate != null ? this.defaultEmailTemplate.Id : null;
      if (e.Event_Invite_Template__c == 'Manual')
      {
          my_et_id = null;
      }
      else if (e.Event_Invite_Template__c != null && e.Event_Invite_Template__c != '' && e.Event_Invite_Template__c != calInviteTemplate)
      {
        EmailTemplate my_et = null;
        try
        {
          List<EmailTemplate> ets = [SELECT id FROM EmailTemplate WHERE name =: e.Event_Invite_Template__c LIMIT 1];
          if (ets.size() > 0)
          {
            my_et = ets.get(0);
          }
          else
          {
              system.debug('Missing Email Template : ' + e.Event_Invite_Template__c);
          }
        }
        catch (DMLException de)
        {
          system.debug('Error retrieving Email Template : ' + e.Event_Invite_Template__c + '. ' + de.getMessage());
        }
        if (my_et != null)
        {
          my_et_id = my_et.Id;
        }
      }
      
      Id my_owea_id = this.defaultOrgWideEmailAddress != null ? this.defaultOrgWideEmailAddress.Id : null;
      String organizer = this.defaultOrgWideEmailAddress != null ? this.defaultOrgWideEmailAddress.DisplayName : null;
      String organizer_email = this.defaultOrgWideEmailAddress != null ? this.defaultOrgWideEmailAddress.Address : null;
      
      if (e.Event_Organizer__c == 'Current User')
      {
        my_owea_id = null;
        organizer = UserInfo.getName();
        organizer_email = UserInfo.getUserEmail();
      }
      // FUTURE EXPANSION : Add "Event Owner" option
      else if (e.Event_Organizer__c != null && e.Event_Organizer__c != '' && e.Event_Organizer__c != calInviteEmail)
      {
        OrgWideEmailAddress my_owea = null;
        try
        {
          List<OrgWideEmailAddress> oweas = [SELECT id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName =: e.Event_Organizer__c LIMIT 1];
          if (oweas.size() > 0)
          {
              my_owea = oweas.get(0);
          }
          else
          {
              system.debug('Missing Org Wide Email Address : ' + e.Event_Organizer__c);
          }
        }
        catch (DMLException de)
        {
          system.debug('Error retrieving Org Wide Email Address : ' + e.Event_Organizer__c + '. ' + de.getMessage());
        }
        if (my_owea != null)
        {
          my_owea_id = my_owea.Id;
          organizer = my_owea.DisplayName;
          organizer_Email = my_owea.Address;
        }
      }
      
      EmailData retVal = new EmailData();
      retVal.EmailTemplateId = my_et_id;
      retVal.OrgWideEmailAddressId = my_owea_id;
      retVal.organizer = organizer;
      retVal.organizer_email = organizer_email;
      return retVal;
  }
  
  
}