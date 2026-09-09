export default class AeonRequest {
    constructor(configData, formData = new FormData(),
                joinVolumes = true, includeTitles = true) {
        this.items = 0;
        this.formData = formData;
        this.configData = configData;
        this.joinVolumes = joinVolumes;
        this.includeTitles = includeTitles;
        this.addConfigFields();
    }

    addConfigFields() {
        this.formData.append('SystemID', this.configData.requestSystemId);
        this.formData.append('AeonForm', this.configData.requestAeonForm);
        this.formData.append('WebRequestForm', this.configData.requestWebRequestForm);
        this.formData.append('SubmitButton', this.configData.requestSubmitValue);
        this.formData.append('ReturnLinkUrl', window.location);
        this.formData.append('ReturnLinkSystemName', this.configData.requestSystemName);
        this.formData.append('Site', this.configData.requestSite);
        this.formData.append('Location', this.configData.requestLocation);
        this.formData.append('Sublocation', this.configData.requestSubLocation);
        this.formData.append('CallNumber', this.configData.requestCallNumber || 'n/a');
        this.formData.append('Title', this.configData.requestTitle);
    }

    addScanFulfillmentFields() {
        this.formData.append('RequestType', 'Copy');
    }

    addLoanFulfillmentFields() {
        this.formData.append('RequestType', 'Loan');
        this.formData.append('UserReview', 'No');
    }

    addItems(items) {
        const processedItems = new Map();

        items.forEach(item => {
            this.addProcessedItem(processedItems, item);
        });

        for (const item of processedItems.values()) {
            this.items += 1;
            this.formData.append('Request', this.items);
            this.appendItemFields(this.items, {
                ItemVolume: item.volume,
                ItemIssue: item.issues.join(', ').slice(0, 255),
                ItemNumber: item.barcode,
            });
        }
    }

    addProcessedItem(processedItems, item) {
        const volume = item.dataset.volume;
        const issue = this.stripMarkup(
            this.includeTitles
                ? `${item.dataset.issue} [${item.dataset.title}]`
                : item.dataset.issue
        );

        const key = this.joinVolumes
            ? volume
            : Symbol(); // symbol is a arbitrary unique value

        if (!processedItems.has(key)) {
            processedItems.set(key, {
                volume,
                issues: [],
                barcode: item.dataset.barcode,
                call_number: item.dataset.call_number
            });
        }

        processedItems.get(key).issues.push(issue);
    }

    appendItemFields(index, fields) {
        for (const [name, value] of Object.entries(fields)) {
            this.formData.append(`${name}_${index}`, value);
        }
    }

    reset() {
        this.formData = new FormData();
    }

    stripMarkup(html){
        let doc = new DOMParser().parseFromString(html, 'text/html');
        return doc.body.textContent || "";
    }
}