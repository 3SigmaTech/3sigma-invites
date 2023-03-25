global class CalendarInviteTriggers extends CalendarInviteBase
{
  global CalendarInviteTriggers() {}
    
  // Called from Event Trigger
  public void CreateInvite(List<Event> elist)
  {
    Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
    String calInviteId = settings.Event_Record_ID__c;
    
    for (integer endx = 0; endx < elist.size(); endx++)
    {
      Event e = getEvent(elist.get(endx).Id, null, null);
      
      if (e.RecordTypeId != calInviteID && calInviteID != '' && calInviteID != null )
      {
        continue;
      }

      List<EventRelation> erlist = [Select Id, RelationId, Status, RespondedDate, Response FROM EventRelation WHERE IsWhat = false AND EventId =: e.Id];

      EventInvite__c ei = new EventInvite__c (
        OwnerId = e.OwnerId
      );
      insert ei;
      e.Event_Invite__c = ei.Id;
      update e;
      
      // Back-reference Event Invite
      String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
      
      if (e.WhatId != null && ((string)e.WhatId).startsWith(casePrefix))
      {
          Case myCase = [SELECT Id, Event_Invite__c FROM Case Where Id =: e.WhatId LIMIT 1];
          myCase.Event_Invite__c = ei.Id;
          update myCase;
      }
      
      List<EventInviteResponse__c> eirlist = new List<EventInviteResponse__c>();

      for (integer ndx = 0; ndx < erlist.size(); ndx++)
      {
        EventRelation er = erlist.get(ndx);
        EventInviteResponse__c eir = new EventInviteResponse__c (
          event_invite__c = ei.Id,
          invitee__c = er.RelationId
        );
        eirlist.add(eir);
      }
      insert eirlist;

      EmailData myData = GetEmailDataFromEvent(e, settings);

      for (EventInviteResponse__c eir : eirlist)
      {
        SendEmail(eir.invitee__c, eir.Id, myData.EmailTemplateId, myData.OrgWideEmailAddressId, e.invite_email_subject__c, e.invite_email_body__c);
      }
    }
  }
  
  // For when date or destination change on CASE object
  public void UpdateInvite(List<Case> cases, Map<Id, Case> newMap, Map<Id, Case> oldMap)
  { 
      Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
      
      List<Id> cIds = new List<Id>();
      List<Id> cEIids = new List<Id>();
      List<Id> skips = new List<Id>();
      
      for (Case c : cases)
      {
          Case oldC = oldMap.get(c.Id);
          Case newC = newMap.get(c.Id);
          if (
              newC.Invite_Destination__c != oldC.Invite_Destination__c
              ||
              (
               (
                newC.Invite_Date_Time__c != oldC.Invite_Date_Time__c
                ||
                newC.Invite_End_Date_Time__c != oldC.Invite_End_Date_Time__c
               )
               &&
               newC.Contact_Timezone__c == oldC.Contact_Timezone__c
              )
             )
          {
              cIds.add(c.Id);
              cEIids.add(c.Event_Invite__c);
          }
          else
          {
              skips.add(c.Id);
          }
      }
      if (cEIids.size() == 0)
      {
          return;
      }
      
      List<Event> allE = [SELECT Id, WhatId, Event_Invite__c, Subject, Description, Location, StartDateTime, EndDateTime
                            FROM Event
                           WHERE Event_Invite__c in :cEIids
                             AND RecordTypeId = :settings.Event_Record_ID__c
                         ];
      if (allE.size() == 0)
      {
          return;
      }
      
      Map<Id, Case> updateCases = new Map<Id, Case>(
          [SELECT Id, Subject, Description, ContactId
                , Event_Invite__c, Invite_Date_Time__c, Invite_End_Date_Time__c
                , Invite_Destination__r.Name, Invite_Destination__r.BillingAddress
             FROM Case
            WHERE Id in :cIds
          ]
      );
      
      List<Event> updateEvents = new List<Event>();
      for (Case c : cases)
      {
          if (skips.contains(c.Id))
          {
              continue;
          }
          
          Event uEvent = null;
          for (Event e : allE)
          {
              if (e.WhatId == c.Id && e.Event_Invite__c == c.Event_Invite__c)
              {
                  uEvent = e;
                  break;
              }
          }
          
          if (uEvent == null)
          {
              continue;
          }
          
          c = updateCases.get(c.Id);
          
          boolean nU = false; // nU = needsUpdate
          
          //nU = nU || (uEvent.Subject <> c.Subject);
          //nU = nU || (uEvent.Description <> c.Description);
          nU = nU || (uEvent.Location <> CalculateLocation(c));
          nU = nU || (uEvent.StartDateTime <> c.Invite_Date_Time__c);
          nU = nU || (uEvent.EndDateTime <> CalculateEndDate(c));
          
          if (!nU)
          {
              continue;
          }
          
          uEvent.Send_Invite_Update__c = true;
          uEvent.Subject = c.Subject;
          uEvent.Description = c.Description;
          uEvent.Location = CalculateLocation(c);
          uEvent.StartDateTime = c.Invite_Date_Time__c;
          uEvent.EndDateTime = CalculateEndDate(c);
          
          updateEvents.add(uEvent);
      }
      if (updateEvents.size() > 0)
      {
          // Update the event; the rest is handled below - (below is called from Event update trigger)
          update updateEvents;
      }            
  }

  // Called from Event Trigger
  public void UpdateInvite(List<Event> elist, Map<Id, Event> newEvents, Map<Id, Event> oldEvents)
  {
    Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
    String calInviteId = settings.Event_Record_ID__c;
    calInviteId = (calInviteId == null ? '' : calInviteId);
    
    // elist = getEvents(newEvents.keySet(), null, null); // commented out as there are no subqueries/subfields needed
    List<Event> updateEvents = new List<Event>();
    
    for (Event e : elist)
    {
      if (e.RecordTypeId != calInviteId || e.Event_Invite__c == null || e.Send_Invite_Update__c == false)
      {
        continue;
      }
      
      Event oldE = oldEvents.get(e.Id);
      Event newE = newEvents.get(e.Id);
      
      if (newE.StartDateTime == oldE.StartDateTime && newE.EndDateTime == oldE.EndDateTime && newE.Location == oldE.Location)
      {
          continue;
      }
      
      // INEFFICIENCY FOLLOWS
      List<EventInviteResponse__c> eirlist = [SELECT Id, Invitee__c FROM EventInviteResponse__c WHERE Event_Invite__c = :e.Event_Invite__c AND Response__c <> 'Canceled'];

      EmailData myData = GetEmailDataFromEvent(e, settings);

      for (EventInviteResponse__c eir : eirlist)
      {
        SendEmail(eir.invitee__c, eir.Id, myData.EmailTemplateId, myData.OrgWideEmailAddressId, 'Updated: ' + e.invite_email_subject__c, e.invite_email_body__c);
      }
      
      Event ue = new Event(Id = e.Id);
      ue.Send_Invite_Update__c = false;
      updateEvents.add(ue);
    }
    if (updateEvents.size() > 0)
    {
        update updateEvents;
    }
  }
  
  public void AddInvitees(List<EventInviteResponse__c> eirs) // For when invitee is added to event via web portal
  { 
      Calendar_Invite__c settings = Calendar_Invite__c.getInstance(Userinfo.getUserId());
      String calInviteId = settings.Event_Record_ID__c;
      
      for (EventInviteResponse__c eir : eirs)
      {
          if (eir.Invite_Source__c != 'Added Via Invite')
          {
              continue;
          }
          
          eir = [SELECT Id, Invite_Source__c, event_invite__c, invitee__c 
                   FROM EventInviteResponse__c 
                  WHERE Id =: eir.Id
                ];
          Event e = getEvent(null, eir.event_invite__c, null);
          
          EmailData myData = GetEmailDataFromEvent(e, settings);
          
          SendEmail(eir.invitee__c, eir.Id, myData.EmailTemplateId, myData.OrgWideEmailAddressId, e.invite_email_subject__c, e.invite_email_body__c);
      }
      
  }
  
  public static void RemoveInvitee() { // For when invitee is removed from event
  }
  
  
  // Called from Trigger_Contact
  public void UpdateTimezone(Map<Id, Contact> newContacts, Map<Id, Contact> oldContacts)
  {
      List<Case> cs = [SELECT Id, ContactId, x3st_invites__Contact_Timezone__c FROM Case WHERE ContactId in :newContacts.keySet()];
      if (cs.size() == 0)
      {
          return;
      }
      boolean hasUpdate = false;
      for (Case c : cs)
      {
          Contact oldCo = oldContacts.get(c.ContactId);
          Contact newCo = newContacts.get(c.ContactId);
          
          if (oldCo.Merged_Timezone__c != newCo.Merged_Timezone__c && c.Contact_Timezone__c != newCo.Merged_Timezone__c)
          {
              c.Contact_Timezone__c = newCo.Merged_Timezone__c;
              hasUpdate = true;
          }
      }
      if (hasUpdate)
      {
          update cs;
      }
  }
  
  // Called from Trigger_Case
  public void UpdateTimezone(List<Case> cases, Map<Id, Case> newCases, Map<Id, Case> oldCases)
  {
      List<Id> toUpdate = new List<Id>();
      for (Case c : cases)
      {
          Case oldC = oldCases.get(c.Id);
          Case newC = newCases.get(c.Id);
          
          if (oldC.Contact_Timezone__c != newC.Contact_Timezone__c)
          {
              toUpdate.add(c.Id);
          }
      }
      
      Map<Id, Contact> toSync = new Map<Id, Contact>();
      for (Id cId : toUpdate)
      {
          Case c = newCases.get(cId);
          
          if (!toSync.containsKey(c.ContactId))
          {
              Contact co = new Contact(Id = c.ContactId);
              co.Timezone__c = c.Contact_Timezone__c;
              toSync.put(co.Id, co);
          }
      }
      
      if (toSync.size() > 0)
      {
          update toSync.values();
      }
  }
  
  // Called from Trigger_Case
  public void SetTimezone(List<Case> cases)
  {
      Set<Id> contactIds = new Set<Id>();
      for (Case c : cases)
      {
          if (c.ContactId == null)
          {
              continue;
          }
          if (c.Contact_Timezone__c == '' || c.Contact_Timezone__c == null)
          {
              contactIds.add(c.ContactId);
          }
      }

      Map<Id, Contact> cos = new Map<Id, Contact>([SELECT Id, Merged_Timezone__c FROM Contact WHERE Id in :contactIds]);
      
      List<Case> cUpdates = new List<Case>();
      for (Case c : cases)
      {
          if (c.ContactId == null)
          {
              continue;
          }
          Contact co = cos.get(c.ContactId);
          if (co == null)
          {
              continue;
          }
          if (c.Contact_Timezone__c == '' || c.Contact_Timezone__c == null)
          {
              c.Contact_Timezone__c = co.Merged_Timezone__c;
          }
      }
  }
  
  // Called from Trigger_Case.BeforeUpdate
  public void UpdateInviteTimes(List<Case> cases, Map<Id, Case> newCases, Map<Id, Case> oldCases)
  {
      for (Case c : cases)
      {
          if (c.Adjust_For_Timezone__c && c.Contact_Timezone__c != '' && c.Contact_Timezone__c != null)
          {
              Case oldC = oldCases.get(c.Id);
              Case newC = newCases.get(c.Id);
              
              if (oldC.Invite_Date_Time__c == newC.Invite_Date_Time__c && oldC.Invite_End_Date_Time__c == newC.Invite_End_Date_Time__c && oldC.Contact_Timezone__c == newC.Contact_Timezone__c)
              {
                  continue;
              }
              
              List<integer> userOffset = getUserOffset();
              
              // Below will adjust time if contact updates their timezone via the calendar invite site
              if (oldC.Contact_Timezone__c != newC.Contact_Timezone__c && UserInfo.getUserType() == 'Guest')
              {
                  userOffset = getTimezoneOffset(oldC.Contact_Timezone__c);
              }
              List<integer> contactOffset = getTimezoneOffset(c.Contact_Timezone__c);
              
              if (userOffset == contactOffset)
              {
                  continue;
              }
              adjustCaseTimes(c, userOffset, contactOffset);
          }
      }
  }
  
  private void adjustCaseTimes(Case c, List<integer> currentOffsets, List<integer> targetOffsets)
  {
      integer hDiff = currentOffsets[0] - targetOffsets[0];
      integer mDiff = currentOffsets[1] - targetOffsets[1];
      
      if (hDiff == 0 && mDiff == 0)
      {
          return;
      }
      
      if (c.Invite_Date_Time__c != null)
      {
          c.Invite_Date_Time__c = c.Invite_Date_Time__c.addHours(hDiff).addMinutes(mDiff);
      }
      
      if (c.Invite_End_Date_Time__c != null)
      {
          c.Invite_End_Date_Time__c = c.Invite_End_Date_Time__c.addHours(hDiff).addMinutes(mDiff);
      }
  }
  
  private List<integer> getUserOffset()
  {
      string strOffset = System.now().format('Z');  
      string strOffsetHours = strOffset.substring(0,3); 
    
      if(strOffsetHours.startsWith('+'))  
      { 
          strOffsetHours = strOffsetHours.substring(1); 
      } 
      integer iMinutes = 100 * integer.valueOf(strOffset.substring(3));
      
      return new List<integer> { integer.valueOf(strOffsetHours) , iMinutes }; 
  }
  
  private List<integer> getTimezoneOffset(string tzfull)
  {
      string tz = tzfull.split('\\ ')[0].replace('GMT','').replace('+','');
      
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
      return new List<integer>{ tzhr , tzmin };
  }
  
}