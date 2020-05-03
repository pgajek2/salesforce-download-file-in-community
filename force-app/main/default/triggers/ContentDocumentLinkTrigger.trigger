trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        String lhwDocumentPrefix = Schema.getGlobalDescribe().get('Document__c').getDescribe().getKeyPrefix();
        for (ContentDocumentLink cdl : Trigger.New) {
            if (String.valueOf(cdl.LinkedEntityId).startsWithIgnoreCase(lhwDocumentPrefix)) {
                cdl.Visibility = 'AllUsers';
            }
        }
    }
}