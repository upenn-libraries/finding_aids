import { Controller } from "@hotwired/stimulus"

const STEPS = ['review', 'submit']

class AeonRequest {
    // configData should be dataset from requestBar
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
    }

    addScanFulfillmentFields() {
        this.formData.append('RequestType', 'Copy')
    }

    addLoanFulfillmentFields() {
        this.formData.append('RequestType', 'Loan')
        this.formData.append('UserReview', 'No') // TODO: r u sure?
    }

     addItem(itemData) {
        this.items += 1
        const volumeInfo = itemData.barcode ? `${itemData.volume} [${itemData.barcode}]` : itemData.volume
        this.formData.append(this.indexParamName(this.items, 'Request'), this.items)
        this.formData.append(this.indexParamName(this.items, 'Site'), this.configData.requestSite)
        this.formData.append(this.indexParamName(this.items, 'Location'), this.configData.requestLocation)
        this.formData.append(this.indexParamName(this.items, 'Sublocation'), this.configData.requestSubLocation)
        this.formData.append(this.indexParamName(this.items, 'CallNumber'), (itemData.call_number || 'n/a'))
        this.formData.append(this.indexParamName(this.items, 'ItemVolume'), volumeInfo)
        this.formData.append(this.indexParamName(this.items, 'ItemIssue'), itemData.issue)

    }

    indexParamName(index, name) {
        return `${name}_${index}`
    }

    addLoanSubmitFields() {
        // TODO: add fields from step2
    }

    addScanSubmitFields() {

    }

}

export default class extends Controller {
    static targets = [
        'requestBar', 'requestBarText',
        'containerCheckbox',
        'requestDialog', 'modalTitle', 'stepNumber',
        'stepSection',
        'listItemTemplate', 'scanItemListArea', 'visitItemListArea'
    ]


    // keep state in the DOM - this is Stimulus
    static values = {
        active: { type: Boolean, default: false },
        type: { type: String, default: '' },
        currentStep: { type: String, default: '' }
    }

    // -- controller lifecycle

    connect() {
        this.activeValue = this.selectedItems().length > 0
        this.aeonRequest = new AeonRequest(this.requestBarTarget.dataset)
    }

    // -- value callbacks --

    activeValueChanged() {
        this.requestBarTarget.hidden = !this.activeValue
    }

    currentStepValueChanged() {
        this.hideStepSections()
        this.activateCurrentStep()
    }

    // -- actions from elements --

    close() {
        this.itemListArea().querySelector('.fa-request__list').innerHTML = ''
        this.activeValue = this.selectedItems().length > 0
        this.requestDialogTarget.close()
        this.aeonRequest = null
        this.currentStepValue = ""
    }

    containerClicked() {
        const selected = this.selectedItems().length
        this.activeValue = selected > 0
        this.requestBarTextTarget.innerHTML =
            `<strong>${selected}</strong> item${selected === 1 ? '' : 's'} selected`
        // TODO: update heading of event.target parent panel with count
    }

    initiateCopyRequest() {
        this.typeValue = 'scan'
        this.initializeModal()
    }

    initiateVisitRequest() {
        this.typeValue = 'visit'
        this.initializeModal()
    }

    removeItem(event) {
        const li = event.target.parentElement
        const checkbox = this.selectedItems().find(item => (
            [item.dataset.volume, item.dataset.issue].join(', ') ===
            li.querySelector('.fa-request__meta').textContent )
        )
        checkbox.checked = false
        li.remove()
        this.toggleItemListElements()
    }

    clearAll() {
        this.itemListArea().querySelector('.fa-request__list').innerHTML = ''
        this.selectedItems().forEach(item_input => { item_input.checked = false })
        this.toggleItemListElements()
    }

    itemsSelected() {
        this.selectedItems().forEach(item => { this.aeonRequest.addItem(item.dataset) })
        this.currentStepValue = 'submit'
    }

    backToReview() {
        this.currentStepValue = 'review'
    }

    submitRequest() {
        const form = document.createElement('form')
        form.method = 'POST'
        form.action = this.aeonRequest.configData.requestEndpoint
        form.hidden = true

        for (const [name, value] of this.aeonRequest.formData) {
            const input = document.createElement("input");
            input.type = "hidden";
            input.name = name;
            input.value = value;
            form.appendChild(input);
        }

        document.body.append(form)
        form.submit()
    }

    // -- support functions --


    buildItemList() {
        this.toggleItemListElements()
        this.itemListArea().querySelector('.fa-request__list').innerHTML = ''
        this.selectedItems().forEach(item => {
            const li = this.listItemTemplateTarget.content.firstElementChild.cloneNode(true)
            li.querySelector('strong').innerHTML = item.dataset.title
            li.querySelector('.fa-request__meta').textContent = [item.dataset.volume, item.dataset.issue].join(', ')
            this.itemListArea().querySelector('.fa-request__list').appendChild(li)
        })
    }

    setModalTitle() {
        const dataset = this.modalTitleTarget.dataset
        this.modalTitleTarget.textContent = this.typeValue === 'scan' ? dataset.scanTitle : dataset.visitTitle
    }

    activateCurrentStep() {
        if (this.activeSection()) {
            this.activeSection().hidden = false
            this.stepNumberTarget.textContent = STEPS.indexOf(this.currentStepValue) + 1
        }
    }

    activeSection() {
        return this.stepSectionTargets.find(section =>
            section.dataset.requestSection === this.currentStepValue &&
            section.dataset.requestType === this.typeValue
        )
    }

    hideStepSections(){
        this.stepSectionTargets.forEach(panel => { panel.hidden = true })
    }

    itemListArea() {
        if(this.typeValue === 'scan') {
            return this.scanItemListAreaTarget
        } else {
            return this.visitItemListAreaTarget
        }
    }

    selectedItems() {
        return this.containerCheckboxTargets.filter(input => input.checked)
    }

    toggleItemListElements() {
        const itemIsSelected = this.selectedItems().length > 0
        this.itemListArea().querySelector('.fa-request__empty').hidden = itemIsSelected
        this.itemListArea().querySelector('.fa-request__review-lede').hidden = !itemIsSelected
        this.activeSection().querySelector('.fa-request__footer').hidden = !itemIsSelected
    }

    initializeModal() {
        this.setModalTitle()
        this.requestDialogTarget.showModal()
        this.currentStepValue = 'review'
        this.buildItemList()
    }
}