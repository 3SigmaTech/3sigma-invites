trigger Trigger_Contact on Contact (after update) 
{
    if (trigger.isAfter && trigger.isUpdate)
    {
        CalendarInviteTriggers cIt = new CalendarInviteTriggers();
        cIt.UpdateTimezone(trigger.newMap, trigger.oldMap);
    }
}