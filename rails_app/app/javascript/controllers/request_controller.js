import { Controller } from "@hotwired/stimulus"

const STEPS = ['review', 'submit']

class AeonRequest {
    // configData should be dataset from requestBar
    constructor(configData, formData = new FormData()) {
        this.items = 0
        this.formData = formData
        this.addConfigFields(configData)
    }

    addConfigFields(configData) {
        this.submitUrl = configData.requestEndpoint
        this.formData.append('SystemID', configData.requestSystemId)
        this.formData.append('AeonForm', configData.requestAeonForm)
        this.formData.append('WebRequestForm', configData.requestWebRequestForm)
        this.formData.append('SubmitButton', configData.requestSubmitValue)
    }

    addScanFulfillmentFields() {
        this.formData.append('RequestType', 'Copy')
    }

    addLoanFulfillmentFields() {
        this.formData.append('RequestType', 'Loan')
        this.formData.append('UserReview', 'No') // TODO: r u sure?
    }


    /* TODO: add these with index value in param name
     * Request: number,
     *   CallNumber: request.call_number,
     *   ItemTitle: request.title,
     *   Site: repository.site,
     *   SubLocation: repository.sublocation,
     *   Location: repository.location,
     *   ItemVolume: volume,
     *   ItemIssue: issue
     */

    addItem(selectedChackbox) {
        this.items += 1
        this.formData.append('field', 'value')
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
        this.itemListArea().querySelector('.fa-visit__list').innerHTML = ''
        this.activeValue = this.selectedItems().length > 0
        this.requestDialogTarget.close()
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
            item.dataset.containers.replace('|',', ') ===
            li.querySelector('.fa-visit__meta').textContent )
        )
        checkbox.checked = false
        li.remove()
        this.toggleItemListElements()
    }

    clearAll() {
        this.itemListArea().querySelector('.fa-visit__list').innerHTML = ''
        this.selectedItems().forEach(item_input => { item_input.checked = false })
        this.toggleItemListElements()
    }

    itemsSelected() {
        this.selectedItems().forEach(item_input => {
            // this.
        })
        this.currentStepValue = 'submit'
    }

    backToReview() {
        this.currentStepValue = 'review'
    }

    submitRequest() {
        const aeonRequest = {}
        // TODO: submit form
    }

    // -- support functions --

    buildItemList() {
        this.toggleItemListElements()
        this.itemListArea().querySelector('.fa-visit__list').innerHTML = ''
        this.selectedItems().forEach(item_input => {
            const li = this.listItemTemplateTarget.content.firstElementChild.cloneNode(true)
            li.querySelector('strong').innerHTML = item_input.dataset.title
            li.querySelector('.fa-visit__meta').textContent = item_input.dataset.containers.replace('|',', ')
            this.itemListArea().querySelector('.fa-visit__list').appendChild(li)
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
        this.itemListArea().querySelector('.fa-visit__empty').hidden = itemIsSelected
        this.itemListArea().querySelector('.fa-visit__review-lede').hidden = !itemIsSelected
        this.activeSection().querySelector('.fa-visit__footer').hidden = !itemIsSelected
    }

    initializeModal() {
        this.setModalTitle()
        this.requestDialogTarget.showModal()
        this.currentStepValue = 'review'
        this.buildItemList()
    }
}