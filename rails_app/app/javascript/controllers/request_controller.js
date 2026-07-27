import { Controller } from "@hotwired/stimulus"
import RequestStorage from "aeon_request/storage"
import RequestCheckboxes from "aeon_request/checkboxes"
import RequestState from "aeon_request/state"

// Stimulus controller for the finding-aid request modal (Review → Details →
// Auth → Confirm). Orchestrates the aeon_request services and renders state
// + selections to the dialog/bar DOM.

// Connects to: data-controller="request"
export default class extends Controller {
  static targets = [
    "dialog", "step", "title",
    "reviewSection", "reviewLede", "reviewFooter", "empty", "list", "itemTemplate",
    "detailsSection", "form", "dateField", "dateInput", "notes", "formLede",
    "authSection", "authLede", "confirmLabel", "confirmCheck", "loginError",
    "confirmSection", "confirmLede",
    "bar", "barCount", "inventory", "liveRegion"
  ]

  static values = {
    storageKey: String,
    prepareUrl: String,
    copy: Object
  }

  connect() {
    this.state = new RequestState()
    this.storage = new RequestStorage(this.storageKeyValue)
    this.checkboxes = new RequestCheckboxes(this.inventoryTarget)
    this.items = this.storage.read()

    this.dateInputTarget.min = new Date().toISOString().split("T")[0]

    // Selections persist across reloads; ids that no longer match a checkbox stay unchecked.
    this.checkboxes.setCheckedFor(this.items, true)
    this.updateBar()
  }

  // Only handle request checkboxes (data-fa-request-id); ignore other inventory controls.
  toggleItem(event) {
    const checkbox = event.target
    if (!checkbox.dataset || !checkbox.dataset.faRequestId) return

    const id = checkbox.dataset.faRequestId
    if (checkbox.checked) {
      const item = this.checkboxes.readItem(checkbox)
      this.items.push(item)
      this.storage.write(this.items)
      this.updateBar()
      this.announce(this.copyValue.announce_added, { title: item.title, count: this.items.length })
    } else {
      this.removeItem(id)
    }
  }

  removeItem(id) {
    const index = this.items.findIndex((item) => item.id === id)
    if (index === -1) return
    const removed = this.items.splice(index, 1)[0]
    this.storage.write(this.items)
    this.checkboxes.setChecked(id, false)
    this.updateBar()
    this.announce(this.copyValue.announce_removed, { title: removed.title, count: this.items.length })
  }

  removeItemButton(event) {
    const id = event.params.id
    this.removeItem(id)
    this.render()
    // Keep focus in the modal: first remaining Remove button, else dialog.
    const next = this.listTarget.querySelector('[data-action*="removeItemButton"]')
    if (next) next.focus()
    else this.dialogTarget.focus()
  }

  clearAll() {
    this.checkboxes.setCheckedFor(this.items, false)
    this.items = []
    this.storage.clear()
    this.updateBar()
    this.render()
    this.dialogTarget.focus()
  }

  openVisit() { this.openDialog("visit") }
  openCopy() { this.openDialog("copy") }

  openDialog(type) {
    this.state.openDialog(type)
    this.render()
    this.dialogTarget.showModal()
    this.focusStep()
  }

  goReview() { this.goStep("review") }
  goDetails() { this.goStep("details") }

  goStep(step) {
    this.state.goStep(step)
    this.render()
    this.focusStep()
  }

  submitDetails(event) {
    event.preventDefault()
    this.goStep("auth")
  }

  toggleLogin(event) {
    this.state.toggleLogin(event.target.checked)
    this.render()
  }

  // POST to /requests/prepare, then submit a hidden form to Aeon (navigates away).
  async place() {
    if (!this.state.confirmedLogin) {
      this.state.failLogin()
      this.render()
      this.confirmCheckTarget.focus()
      return
    }

    const params = this.buildRequestParams()

    try {
      const response = await fetch(this.prepareUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify(params)
      })

      if (!response.ok) {
        const error = await response.json()
        console.error("Request preparation failed:", error)
        return
      }

      const { url, body } = await response.json()
      // Clear selections so a returning visitor doesn't re-request the same items.
      this.items = []
      this.storage.clear()
      this.submitToAeon(url, body)
    } catch (err) {
      console.error("Error preparing request:", err)
    }
  }

  buildRequestParams() {
    const formData = new FormData(this.formTarget)
    const params = {
      repository: this.getMetaContent("repository"),
      title: this.getMetaContent("title"),
      call_num: this.getMetaContent("call-num"),
      request_type: this.state.requestType === "visit" ? "Loan" : "Copy",
      special_request: formData.get("special-request") || "",
      notes: formData.get("notes") || "",
      retrieval_date: formData.get("retrieval-date") || "",
      save_for_later: formData.get("save-for-later") === "on" ? "1" : "0",
      return_url: window.location.href,
      item: [],
      item_barcode: []
    }

    this.items.forEach((item) => {
      params.item.push(item.container || item.title)
      params.item_barcode.push(item.barcode || "")
    })

    return params
  }

  getMetaContent(name) {
    const meta = document.querySelector(`meta[name="${name}"]`)
    return meta ? meta.content : ""
  }

  submitToAeon(url, body) {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = url
    form.target = "_self"
    form.style.display = "none"

    for (const [key, value] of Object.entries(body)) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = key
      input.value = value
      form.appendChild(input)
    }

    document.body.appendChild(form)
    form.submit()
    // No need to clean up - we're navigating away
  }

  close() {
    this.dialogTarget.close()
  }

  // Native <dialog> can also close via Escape; nothing to reset.
  onDialogClose() { /* no-op */ }

  copyFor(key) {
    return this.copyValue[this.state.requestType][key]
  }

  render() {
    this.titleTarget.textContent = this.copyFor("title")
    this.reviewLedeTarget.textContent = this.copyFor("review_lede")
    this.formLedeTarget.textContent = this.copyFor("form_lede")

    this.stepTarget.textContent =
      this.state.step === "review" ? this.copyValue.step_review
      : this.state.step === "details" ? this.copyFor("step_details")
      : this.state.step === "auth" ? this.copyValue.step_auth
      : ""

    // Toggle `required` with visibility — a hidden required field would block submit on the copy path.
    const wantsDate = this.state.requestType === "visit"
    this.dateFieldTarget.hidden = !wantsDate
    this.dateInputTarget.required = wantsDate

    this.confirmCheckTarget.checked = this.state.confirmedLogin
    this.loginErrorTarget.hidden = !this.state.loginError
    this.confirmLabelTarget.classList.toggle("fa-visit__confirm--error", this.state.loginError)

    this.renderList()

    const sections = {
      review: this.reviewSectionTarget,
      details: this.detailsSectionTarget,
      auth: this.authSectionTarget,
      confirm: this.confirmSectionTarget
    }
    Object.values(sections).forEach((section) => { section.hidden = true })
    if (sections[this.state.step]) sections[this.state.step].hidden = false
  }

  renderList() {
    this.listTarget.textContent = ""
    this.emptyTarget.hidden = this.items.length > 0
    // When empty, hide the intro and actions; leave only the empty prompt.
    this.reviewLedeTarget.hidden = this.items.length === 0
    this.reviewFooterTarget.hidden = this.items.length === 0

    this.items.forEach((item) => {
      const li = this.itemTemplateTarget.content.firstElementChild.cloneNode(true)
      li.querySelector("strong").textContent = item.title
      li.querySelector(".fa-visit__meta").textContent = this.itemMeta(item) + (item.dates ? " · " + item.dates : "")
      const button = li.querySelector("button")
      button.textContent = this.copyValue.remove
      button.setAttribute("aria-label", this.interp(this.copyValue.remove_aria, { title: item.title }))
      button.dataset.requestIdParam = item.id
      this.listTarget.appendChild(li)
    })
  }

  itemMeta(item) {
    return item.container || this.copyValue.no_container
  }

  focusStep() {
    const focusByStep = {
      review: this.dialogTarget,
      details: this.state.requestType === "visit" ? this.dateInputTarget : this.notesTarget,
      auth: this.authLedeTarget,
      confirm: this.confirmLedeTarget
    }
    focusByStep[this.state.step]?.focus()
  }

  updateBar() {
    this.barCountTarget.textContent = this.formatCount(this.items.length)
    this.barTarget.hidden = this.items.length === 0
    // Reserve room so the fixed bar never covers the last of the page.
    document.body.classList.toggle("fa-visit-bar-visible", this.items.length > 0)
    this.refreshSectionCounts()
  }

  formatCount(n) {
    return n === 1
      ? this.copyValue.bar_count_one
      : this.interp(this.copyValue.bar_count_many, { count: n })
  }

  // aria-hidden keeps the live count out of the heading's accessible name (the live region carries spoken feedback).
  refreshSectionCounts() {
    this.checkboxes.tally().forEach(({ section, count }) => {
      const summary = section.querySelector(":scope > summary")
      if (!summary) return
      let span = summary.querySelector(".fa-visit__section-count")
      if (!span) {
        const heading = summary.querySelector("h3, h4, h5, h6")
        if (!heading) return
        span = document.createElement("span")
        span.className = "fa-visit__section-count fa-small-name"
        span.setAttribute("aria-hidden", "true")
        heading.appendChild(span)
      }
      span.textContent = count ? this.interp(this.copyValue.section_count, { count }) : ""
    })
  }

  announce(template, vars) {
    if (this.hasLiveRegionTarget) this.liveRegionTarget.textContent = this.interp(template, vars)
  }

  interp(template, vars) {
    return template.replace(/%\{(\w+)\}/g, (_, key) => (vars[key] ?? ""))
  }
}
