export default class AeonRequest {
    constructor(configData, formData = new FormData()) {
        this.items = 0
        this.formData = formData
        this.configData = configData
        this.addConfigFields()
    }

    addConfigFields() {
        this.formData.append('SystemID', this.configData.requestSystemId)
        this.formData.append('AeonForm', this.configData.requestAeonForm)
        this.formData.append('WebRequestForm', this.configData.requestWebRequestForm)
        this.formData.append('SubmitButton', this.configData.requestSubmitValue)
        this.formData.append('ReturnLinkUrl', window.location)
        this.formData.append('ReturnLinkSystemName', this.configData.requestSystemName)
    }

    addScanFulfillmentFields() {
        this.formData.append('RequestType', 'Copy')
    }

    addLoanFulfillmentFields() {
        this.formData.append('RequestType', 'Loan')
        this.formData.append('UserReview', 'No')
    }

    addItem(itemData) {
        this.items += 1
        const volumeInfo = itemData.barcode ? `${itemData.volume} [${itemData.barcode}]` : itemData.volume
        this.formData.append('Request', this.items)
        this.appendItemFields(this.items, {
            Site: this.configData.requestSite,
            Location: this.configData.requestLocation,
            Sublocation: this.configData.requestSubLocation,
            CallNumber: itemData.call_number || 'n/a',
            ItemVolume: volumeInfo,
            ItemIssue: itemData.issue
        })
    }

    appendItemFields(index, fields) {
        for (const [name, value] of Object.entries(fields)) {
            this.formData.append(`${name}_${index}`, value)
        }
    }

    reset() {
        this.formData = new FormData()
    }
}