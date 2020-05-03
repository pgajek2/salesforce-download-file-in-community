public with sharing class FilesController {
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getAllDocumentsAndRelatedFiles(){
        Map<Id, Document__c> documents = new Map<Id, Document__c>([ SELECT Id, Name, Description__c
                                                                    FROM Document__c ]);

        Map<Id, ContentDocumentLink> contentDocumentLinks = new Map<Id, ContentDocumentLink>([ SELECT Id, LinkedEntityId, ContentDocumentId
                                                                                               FROM ContentDocumentLink
                                                                                               WHERE LinkedEntityId IN: documents.keySet() ]);

        Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([ SELECT Id, Title, FileExtension
                                                                                   FROM ContentDocument
                                                                                   WHERE Id IN: getContentDocumentIds(contentDocumentLinks.values()) ]);

        Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = prepareDocumentIdToContentDocumentListMap(contentDocumentLinks.values(), contentDocuments);

        return prepareDocumentWrapperResponse(documentIdToContentDocumentsList, documents);                                                 
    }

    @AuraEnabled
    public static ContentDistribution getContentDistributionForFile(Id contentDocumentId){

        ContentVersion contentVersion = [ SELECT Id, ContentDocumentId, IsMajorVersion, IsLatest
                                          FROM ContentVersion 
                                          WHERE ContentDocumentId =: contentDocumentId
                                            AND IsLatest = true 
                                          LIMIT 1 ];

        List<ContentDistribution> contentDistribution = [ SELECT Id, Name, ContentDownloadUrl, ContentVersionId 
                                                          FROM ContentDistribution 
                                                          WHERE ContentVersionId =: contentVersion.Id ];
        if (!contentDistribution.isEmpty()) {
            return contentDistribution[0];
        }
        // else create new contentDistribution
        ContentDistribution newContentDistribution = new ContentDistribution( Name = 'Test',
                                                                              ContentVersionId = contentVersion.Id,
                                                                              PreferencesAllowViewInBrowser = true );
        insert newContentDistribution;

        return  [ SELECT Id, Name, ContentDownloadUrl, ContentDocumentId 
                  FROM ContentDistribution 
                  WHERE Id =: newContentDistribution.Id 
                  LIMIT 1 ];
    }

    private static List<Id> getContentDocumentIds(List<ContentDocumentLink> contentDocumentsLinks) {
        List<Id> contentDocumentsIds = new List<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentsLinks) {
            contentDocumentsIds.add(contentDocumentLink.ContentDocumentId);
        }
        return contentDocumentsIds;
    }

    private static Map<Id, List<ContentDocument>> prepareDocumentIdToContentDocumentListMap(List<ContentDocumentLink> contentDocumentsLinks, Map<Id, ContentDocument> contentDocuments) {
        Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = new Map<Id, List<ContentDocument>>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentsLinks) {
            List<ContentDocument> currentContentDocumentList = documentIdToContentDocumentsList.get(contentDocumentLink.LinkedEntityId);
            if (currentContentDocumentList == null) {
                currentContentDocumentList = new List<ContentDocument>();
            } 
            currentContentDocumentList.add(
                contentDocuments.get(contentDocumentLink.ContentDocumentId)
            );
            documentIdToContentDocumentsList.put(contentDocumentLink.LinkedEntityId, currentContentDocumentList);
        }
        return documentIdToContentDocumentsList;
    }

    private static List<DocumentWrapper> prepareDocumentWrapperResponse(Map<Id, List<ContentDocument>> documentIdToContentDocumentsList, Map<Id, Document__c> documents) {
        List<DocumentWrapper> documentsAndFiles = new List<DocumentWrapper>();

        for (Id documentId : documentIdToContentDocumentsList.keySet()) {

            DocumentWrapper documentWrapper = new DocumentWrapper();
            documentWrapper.id = documentId;
            documentWrapper.name = documents.get(documentId).Name;
            documentWrapper.description = documents.get(documentId).Description__c;
            documentWrapper.files = new List<DocumentWrapper.FileWrapper>();

            for (ContentDocument contentDocument : documentIdToContentDocumentsList.get(documentId)) {
                DocumentWrapper.FileWrapper fileWrapper = new DocumentWrapper.FileWrapper();
                fileWrapper.id = contentDocument.Id;
                fileWrapper.name = contentDocument.Title;
                fileWrapper.fileExtension = contentDocument.FileExtension;
                documentWrapper.files.add(fileWrapper);
            }

            documentsAndFiles.add(documentWrapper);
        }

        return documentsAndFiles;
    }
}