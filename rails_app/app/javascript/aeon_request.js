export default class AeonRequest {
    constructor(configData, formData = new FormData()) {
        this.items = 0;
        this.formData = formData;
        this.configData = configData;
        this.addConfigFields();
    }

    addConfigFields() {
        this.formData.append('SystemID', this.configData.requestSystemId);
        this.formData.append('AeonForm', this.configData.requestAeonForm);
        this.formData.append('WebRequestForm', this.configData.requestWebRequestForm);
        this.formData.append('SubmitButton', this.configData.requestSubmitValue);
        this.formData.append('Site', this.configData.requestSite);
        this.formData.append('Location', this.configData.requestLocation);
        this.formData.append('Sublocation', this.configData.requestSublocation);
        this.formData.append('CallNumber', this.configData.requestCallNumber || 'n/a');
        this.formData.append('Title', this.configData.requestTitle);
        this.formData.append('UserReview', 'No');
    }

    addScanFulfillmentFields() {
        this.formData.append('RequestType', 'Copy');
    }

    addLoanFulfillmentFields() {
        this.formData.append('RequestType', 'Loan');
    }

    addItems(items) {
        const processedItems = {};

        items.forEach(item => {
            this.addProcessedItem(processedItems, item);
        });

        Object.entries(processedItems).forEach(([volume, data]) => {
            this.items += 1;
            this.formData.append('Request', this.items);
            this.appendItemFields(this.items, {
                ItemVolume: volume,
                ItemIssue: [...data.issues].join(', ').slice(0, 255),
                ItemNumber: data.barcode,
            });
        });
    }

    addProcessedItem(processedItems, item) {
        if (!processedItems.hasOwnProperty(item.dataset.volume)) {
            processedItems[item.dataset.volume] = {
                issues: new Set,
                barcode: item.dataset.barcode,
                call_number: item.dataset.call_number
            };
        }

        processedItems[item.dataset.volume].issues.add(item.dataset.issue);
    }

    appendItemFields(index, fields) {
        Object.entries(fields).forEach(([name, value]) => {
            this.formData.append(`${name}_${index}`, value);
        })
    }

    reset() {
        this.formData = new FormData();
    }
}