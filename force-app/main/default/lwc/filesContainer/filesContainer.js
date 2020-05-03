import { LightningElement, track, wire } from 'lwc';
import getAllDocumentsAndRelatedFiles from '@salesforce/apex/FilesController.getAllDocumentsAndRelatedFiles';
import getContentDistributionForFile from '@salesforce/apex/FilesController.getContentDistributionForFile';

export default class FilesContainer extends LightningElement {

    @track documents;

    @wire (getAllDocumentsAndRelatedFiles)
    wiredDocuments({error,data}) {
        if (data) {
            console.log(JSON.stringify(data))
            this.documents = data;
        }
        if (error) {
            console.log(JSON.stringify(error))
        }
    }

    handleDownloadFile(e) {
        getContentDistributionForFile({
            contentDocumentId: e.target.dataset.id
        })
        .then(response => {
            console.log(JSON.stringify(response));
            window.open(response.ContentDownloadUrl);
        })
        .catch(error => {
            console.log(JSON.stringify(error));
        })
    }
}