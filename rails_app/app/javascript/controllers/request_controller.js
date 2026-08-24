import { Controller } from "@hotwired/stimulus"
import AeonRequest from "aeon_request"

const STEPS = ['review', 'submit']

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
        this.aeonRequest.reset()
        this.currentStepValue = ""
    }

    containerClicked() {
        const selected = this.selectedItems().length
        this.activeValue = selected > 0
        this.requestBarTextTarget.innerHTML =
            `<strong>${selected}</strong> item${selected === 1 ? '' : 's'} selected`
    }

    initiateCopyRequest() {
        this.typeValue = 'scan'
        this.initializeModal()
        this.aeonRequest.addScanFulfillmentFields()
    }

    initiateVisitRequest() {
        this.typeValue = 'visit'
        this.initializeModal()
        this.aeonRequest.addLoanFulfillmentFields()
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
        this.aeonRequest.addItems(this.selectedItems())
        this.currentStepValue = 'submit'
    }

    backToReview() {
        this.currentStepValue = 'review'
    }

    submitRequest(event) {
        event.preventDefault()
        const form = event.target
        form.method = 'POST'
        form.action = this.aeonRequest.configData.requestEndpoint
        event.submitter.disabled = true

        // swap date fields and format for Aeon
        const rawScheduledDate = new FormData(form).get('rawScheduledDate')
        if(rawScheduledDate) {
            const [yyyy, mm, dd] = rawScheduledDate.split('-')
            this.aeonRequest.formData.set('ScheduledDate', `${mm}/${dd}/${yyyy}`)
            form.querySelector('[name="rawScheduledDate"]')?.remove()
        }

        // append prior values
        for (const [name, value] of this.aeonRequest.formData) {
            const input = document.createElement("input")
            input.type = "hidden"
            input.name = name
            input.value = value
            form.appendChild(input)
        }

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