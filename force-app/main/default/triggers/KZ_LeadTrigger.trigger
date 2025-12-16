trigger KZ_LeadTrigger on Lead (before insert, before update) {
    if (Trigger.isBefore) {
        KZ_LeadScoringHandler.applyScoring(Trigger.new);
    }
}
