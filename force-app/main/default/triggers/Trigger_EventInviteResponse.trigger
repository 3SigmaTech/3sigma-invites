trigger Trigger_EventInviteResponse on EventInviteResponse__c (after insert) 
{
    if (Trigger.isAfter && Trigger.isInsert)
    {
        CalendarInviteTriggers cIt = new CalendarInviteTriggers();
        cIt.AddInvitees(Trigger.new);
    }
}