export default class AeonRequest {
    SYSTEM_NAME = 'Penn Finding Aids site'
    SYSTEM_ID = 'PennFindingAidsSite'
    AEON_FORM = 'ExternalRequest'
    WEB_REQUEST_FORM = 'DefaultRequest'
    SUBMIT_VALUE = 'Submit Request'
    TEXT_FIELD_CHAR_LIMIT = 255

    constructor(configData, formData = new FormData()) {
        this.items = 0;
        this.formData = formData;
        this.configData = configData;
        this.addConfigFields();
    }

    addConfigFields() {
        this.formData.append('SystemID', this.SYSTEM_ID);
        this.formData.append('AeonForm', this.AEON_FORM);
        this.formData.append('WebRequestForm', this.WEB_REQUEST_FORM);
        this.formData.append('SubmitButton', this.SUBMIT_VALUE);
        this.formData.append('ReturnLinkUrl', window.location);
        this.formData.append('ReturnLinkSystemName', this.SYSTEM_NAME);
        this.formData.append('Site', this.configData.requestSite);
        this.formData.append('Location', this.configData.requestLocation);
        this.formData.append('Sublocation', this.configData.requestSublocation);
        this.formData.append('CallNumber', this.configData.requestCallNumber || 'n/a');
        this.formData.append('Title', this.configData.requestTitle);
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
                ItemIssue: [...data.issues].join(', ').slice(0, this.TEXT_FIELD_CHAR_LIMIT),
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

    addUserReview(rawValue) {
        this.formData.append('UserReview', rawValue === 'Yes' ? 'Yes' : 'No');
    }

    addScheduledDate(rawDate) {
        const [yyyy, mm, dd] = rawDate.split('-');
        this.formData.append('ScheduledDate', `${mm}/${dd}/${yyyy}`);
    }

    reset() {
        this.formData = new FormData();
    }
}