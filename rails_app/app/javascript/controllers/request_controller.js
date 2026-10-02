import { Controller } from "@hotwired/stimulus";
import AeonRequest from "aeon_request";

const REVIEW_STEP = 'review'
const SUBMIT_STEP = 'submit'
const STEPS = [REVIEW_STEP, SUBMIT_STEP];


export default class extends Controller {
    static targets = [
        'requestBar', 'requestBarText',
        'containerCheckbox',
        'requestDialog', 'modalTitle', 'stepNumber',
        'stepSection',
        'listItemTemplate', 'scanItemListArea', 'visitItemListArea'
    ];

    static values = {
        active: { type: Boolean, default: false },
        type: { type: String, default: '' },
        currentStep: { type: String, default: '' }
    };

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
        const selected = this.selectedItems().length;
        this.activeValue = selected > 0;
        this.updateStatus(selected);
    }

    initiateCopyRequest() {
        this.typeValue = this.aeonRequest.scanRequestType();
        this.initializeModal();
        this.updateStatus();
        this.aeonRequest.addScanFulfillmentFields();
    }

    initiateVisitRequest() {
        this.typeValue = this.aeonRequest.visitRequestType();
        this.initializeModal();
        this.updateStatus();
        this.aeonRequest.addLoanFulfillmentFields();
    }

    removeItem(event) {
        const li = event.target.parentElement;
        const checkbox = this.selectedItems().find(item => (
            [item.dataset.volume, item.dataset.issue].join(', ') ===
            li.querySelector('.fa-request__meta').textContent )
        )
        checkbox.checked = false;
        li.remove();
        this.updateStatus();
        this.toggleItemListElements();
    }

    clearAll() {
        this.itemListArea().querySelector('.fa-request__list').innerHTML = '';
        this.selectedItems().forEach(itemInput => { itemInput.checked = false });
        this.toggleItemListElements();
        this.updateStatus();
    }

    continueToSubmit() {
        this.currentStepValue = SUBMIT_STEP;
    }

    backToReview() {
        this.currentStepValue = REVIEW_STEP;
    }

    submitRequest(event) {
        event.preventDefault();
        const form = event.target;
        const submitFormData = new FormData(form);
        form.method = 'POST';
        form.action = this.aeonRequest.configData.requestEreEndpoint;
        event.submitter.disabled = true;

        this.aeonRequest.addItems(this.selectedItems());

        // swap date fields and format for Aeon
        const rawScheduledDate = submitFormData.get('rawScheduledDate');
        if(rawScheduledDate) {
            this.aeonRequest.addScheduledDate(rawScheduledDate);
            form.querySelector('[name="rawScheduledDate"]')?.remove();
        }

        // set UserReview param based on checkbox state - only present if checked
        const rawUserReview = submitFormData.get('rawUserReview');
        this.aeonRequest.addUserReview(rawUserReview);
        form.querySelector('[name="rawUserReview"]')?.remove();

        // append prior values
        for (const [name, value] of this.aeonRequest.formData) {
            const input = document.createElement("input");
            input.type = "hidden";
            input.name = name;
            input.value = value;
            form.appendChild(input);
        }

        form.submit();
    }

    // -- support functions --

    updateStatus(checkedCount = this.selectedItems().length) {
        this.requestBarTextTarget.innerHTML =
            `<strong>${checkedCount}</strong> item${checkedCount === 1 ? '' : 's'} selected`;
    }

    buildItemList() {
        this.toggleItemListElements();
        this.itemListArea().querySelector('.fa-request__list').innerHTML = '';
        this.selectedItems().forEach(item => {
            const li = this.listItemTemplateTarget.content.firstElementChild.cloneNode(true);
            li.querySelector('strong').innerHTML = item.dataset.title;
            li.querySelector('.fa-request__meta').textContent = [item.dataset.volume, item.dataset.issue].join(', ');
            this.itemListArea().querySelector('.fa-request__list').appendChild(li);
        });
    }

    setModalTitle() {
        const dataset = this.modalTitleTarget.dataset;
        this.modalTitleTarget.textContent = this.typeValue === this.aeonRequest.scanRequestType() ? dataset.scanTitle : dataset.visitTitle;
    }

    activateCurrentStep() {
        if (this.activeSection()) {
            this.activeSection().hidden = false;
            this.stepNumberTarget.textContent = STEPS.indexOf(this.currentStepValue) + 1;
        }
    }

    activeSection() {
        return this.stepSectionTargets.find(section =>
            section.dataset.requestSection === this.currentStepValue &&
            section.dataset.requestType === this.typeValue
        );
    }

    hideStepSections(){
        this.stepSectionTargets.forEach(panel => { panel.hidden = true });
    }

    itemListArea() {
        if(this.typeValue === this.aeonRequest.scanRequestType()) {
            return this.scanItemListAreaTarget;
        } else {
            return this.visitItemListAreaTarget;
        }
    }

    selectedItems() {
        return this.containerCheckboxTargets.filter(input => input.checked);
    }

    toggleItemListElements() {
        const itemIsSelected = this.selectedItems().length > 0;
        this.itemListArea().querySelector('.fa-request__empty').hidden = itemIsSelected;
        this.itemListArea().querySelector('.fa-request__review-lede').hidden = !itemIsSelected;
        this.activeSection().querySelector('.fa-request__footer').hidden = !itemIsSelected;
    }

    initializeModal() {
        this.setModalTitle();
        this.requestDialogTarget.showModal();
        this.currentStepValue = REVIEW_STEP;
        this.buildItemList();
    }
}