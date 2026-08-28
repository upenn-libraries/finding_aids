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
        this.formData.append('Site', this.configData.requestSite)
        this.formData.append('Location', this.configData.requestLocation)
        this.formData.append('Sublocation', this.configData.requestSubLocation)
        this.formData.append('CallNumber', this.configData.requestCallNumber || 'n/a')
        this.formData.append('Title', this.configData.requestTitle)
    }

    addScanFulfillmentFields() {
        this.formData.append('RequestType', 'Copy')
    }

    addLoanFulfillmentFields() {
        this.formData.append('RequestType', 'Loan')
        this.formData.append('UserReview', 'No')
    }

    addItems(items) {
        const mergedItems = {}

        // merge issues with same volume
        items.forEach(item => {
            mergedItems[item.dataset.volume] ||= {
                issues: [],
                barcode: item.dataset.barcode,
                call_number: item.dataset.call_number
            }
            mergedItems[item.dataset.volume].issues.push(`${item.dataset.issue} [${item.dataset.title}]`)
        })

        // add merged items to formData
        Object.entries(mergedItems).forEach(([volume, item]) => {
            this.items += 1
            this.formData.append('Request', this.items)
            this.appendItemFields(this.items, {
                ItemVolume: volume,
                ItemIssue: item.issues.join(', '), // TODO: we could hit character limit here of 256 - truncate or stop merging volumes
                ItemNumber: item.barcode,
            })
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