trigger Trigger_Event on Event (after insert, after update) // , before update, before insert
{
    /*
    if (Trigger.isBefore) 
    {
        if (Trigger.isUpdate)
        {
            // DNE
        }
        if (Trigger.isInsert)
        {
            // Nothing for now
        }
    }
    */
    
    if (Trigger.isAfter) 
    {
        if (Trigger.isUpdate) 
        {
            CalendarInviteTriggers cIt = new CalendarInviteTriggers();
            cIt.UpdateInvite(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }
        if (Trigger.isInsert)
        {
            CalendarInviteTriggers cIt = new CalendarInviteTriggers();
            cIt.createInvite(Trigger.new);
        }
    }
}