trigger Trigger_Case on Case (before update, after update, before insert) 
{
    if (trigger.isBefore && trigger.isUpdate)
    {
        CalendarInviteTriggers cIt = new CalendarInviteTriggers();
        cIt.UpdateInviteTimes(trigger.new, trigger.newMap, trigger.oldMap);
    }
    else if (trigger.isAfter && trigger.isUpdate)
    {
        CalendarInviteTriggers cIt = new CalendarInviteTriggers();
        cIt.UpdateInvite(trigger.new, trigger.newMap, trigger.oldMap);
        cIt.UpdateTimezone(trigger.new, trigger.newMap, trigger.oldMap);
    }
    else if (trigger.isBefore && trigger.isInsert)
    {
        CalendarInviteTriggers cIt = new CalendarInviteTriggers();
        cIt.SetTimezone(trigger.new);
    }
}