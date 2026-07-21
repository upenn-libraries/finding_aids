import { Controller } from "@hotwired/stimulus"

// Request flow controller for the finding-aid show page.
//
// Reads checkbox state from the inventory table and walks the user through a
// four-step modal: Review → Details → Auth → Confirm. Selections persist in
// localStorage (per collection) so they survive navigation between <details>
// sections and page reloads. Ported from the Philadelphia Area Archives
// mockup's reference implementation.
//
// State is the single source of truth; render() is the only code that writes
// the dialog's DOM. The native <dialog>, focus management, and required-field
// validation are left to the platform.

// Connects to: data-controller="request"
export default class extends Controller {
  static targets = [
    "dialog", "step", "title",
    "reviewSection", "reviewLede", "reviewFooter", "empty", "list",
    "detailsSection", "form", "dateField", "dateInput", "notes", "formLede",
    "authSection", "authLede", "confirmLabel", "confirmCheck", "loginError",
    "confirmSection", "confirmLede",
    "bar", "barCount", "inventory", "liveRegion",
    "meta"
  ]

  static values = {
    storageKey: String, // per-collection localStorage key
    aeonUrl: String,    // Aeon login URL for the auth step link
    prepareUrl: String, // URL for the prepare action (e.g., /requests/prepare)
    copy: Object        // i18n copy variants + dynamic text
  }

  connect() {
    // @type {{ requestType: 'visit'|'copy', step: string, confirmedLogin: boolean, loginError: boolean }}
    this.state = { requestType: "visit", step: "review", confirmedLogin: false, loginError: false }
    this.items = this.readStorage()

    // Block past dates on the visit field. The "at least a week out" hint is
    // guidance, not enforced — staff would rather field a too-soon request
    // than block it.
    this.dateInputTarget.min = new Date().toISOString().split("T")[0]

    // Restore checked state from a previous session. Works inside closed
    // <details>: the checkboxes are in the DOM either way. Stale ids (data
    // regenerated since the items were saved) simply stay unchecked — the
    // stored display fields still render in the dialog.
    this.items.forEach((item) => {
      const checkbox = this.findCheckbox(item.id)
      if (checkbox) checkbox.checked = true
    })
    this.updateBar()
  }

  // --- Storage -----------------------------------------------------------

  readStorage() {
    try {
      const stored = JSON.parse(localStorage.getItem(this.storageKeyValue))
      if (stored && stored.v === 1 && Array.isArray(stored.items)) return stored.items
    } catch (e) { /* fall through to empty */ }
    return []
  }

  writeStorage() {
    try {
      localStorage.setItem(this.storageKeyValue, JSON.stringify({ v: 1, items: this.items }))
    } catch (e) { /* storage may be unavailable; selections still work in-session */ }
  }

  findCheckbox(id) {
    return this.inventoryTarget.querySelector(`[data-fa-request-id="${id}"]`)
  }

  // --- Inventory checkbox changes ---------------------------------------

  // Event-delegated change handler on the inventory container. Only fires for
  // checkboxes that carry a data-fa-request-id (the request checkboxes), so
  // other controls in the inventory are ignored.
  toggleItem(event) {
    const checkbox = event.target
    if (!checkbox.dataset || !checkbox.dataset.faRequestId) return

    const id = checkbox.dataset.faRequestId
    if (checkbox.checked) {
      const cell = checkbox.closest(".fa-visit__cell")
      const item = {
        id: id,
        title: cell.dataset.title,
        dates: cell.dataset.dates,
        container: cell.dataset.container
      }
      this.items.push(item)
      this.writeStorage()
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
    this.writeStorage()
    const checkbox = this.findCheckbox(id)
    if (checkbox) checkbox.checked = false
    this.updateBar()
    this.announce(this.copyValue.announce_removed, { title: removed.title, count: this.items.length })
  }

  // Remove button on a list item. id passed via data-request-id-param.
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
    this.items.forEach((item) => {
      const checkbox = this.findCheckbox(item.id)
      if (checkbox) checkbox.checked = false
    })
    this.items = []
    this.writeStorage()
    this.updateBar()
    this.render()
    this.dialogTarget.focus()
  }

  // --- Dialog state machine ---------------------------------------------

  openVisit() { this.openDialog("visit") }
  openCopy() { this.openDialog("copy") }

  openDialog(type) {
    this.state = { requestType: type, step: "review", confirmedLogin: false, loginError: false }
    this.render()
    this.dialogTarget.showModal()
    this.focusStep()
  }

  goReview() { this.goStep("review") }
  goDetails() { this.goStep("details") }
  goAuth() { this.goStep("auth") }

  goStep(step) {
    this.state.step = step
    this.state.loginError = false
    this.render()
    this.focusStep()
  }

  // The details step is a real <form>, so the required date validates natively
  // on the visit path; a valid submit advances to the log-in gate. It never
  // sends directly (see the gate below).
  submitDetails(event) {
    event.preventDefault()
    this.goStep("auth")
  }

  // Log-in confirmation checkbox gates whether the request can be placed.
  toggleLogin(event) {
    this.state.confirmedLogin = event.target.checked
    if (event.target.checked) this.state.loginError = false
    this.render()
  }

  // Collect form data + selected items, POST to /requests/prepare,
  // then submit a hidden form to Aeon (navigating away from the site).
  async place() {
    if (!this.state.confirmedLogin) {
      this.state.loginError = true
      this.render()
      this.confirmCheckTarget.focus()
      return
    }

    // Build request params from form and selected items
    const params = this.buildRequestParams()

    try {
      const response = await fetch(this.prepareUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.metaTarget.content
        },
        body: JSON.stringify(params)
      })

      if (!response.ok) {
        const error = await response.json()
        console.error("Request preparation failed:", error)
        return
      }

      const { url, body } = await response.json()
      this.submitToAeon(url, body)
    } catch (err) {
      console.error("Error preparing request:", err)
    }
  }

  // Build the params hash to send to the prepare action
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

    // Add selected items
    this.items.forEach((item) => {
      params.item.push(item.container || item.title)
      params.item_barcode.push(item.barcode || "")
    })

    return params
  }

  // Get content from a meta tag
  getMetaContent(name) {
    const meta = document.querySelector(`meta[name="${name}"]`)
    return meta ? meta.content : ""
  }

  // Create a hidden form and submit it to Aeon
  submitToAeon(url, body) {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = url
    form.target = "_self"
    form.style.display = "none"

    // Add all body params as hidden fields
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

  // Native <dialog> can also close via Escape; nothing to reset — selections
  // persist and re-opening starts fresh at review.
  onDialogClose() { /* no-op */ }

  // --- Render: the only code that writes dialog DOM ----------------------

  copyFor(key) {
    return this.copyValue[this.state.requestType][key]
  }

  render() {
    this.titleTarget.textContent = this.copyFor("title")
    this.reviewLedeTarget.textContent = this.copyFor("review_lede")
    this.formLedeTarget.textContent = this.copyFor("form_lede")

    // Three numbered steps: review, details, and confirming log-in. The final
    // confirmation is a terminal state, so it carries no step count.
    this.stepTarget.textContent =
      this.state.step === "review" ? this.copyValue.step_review
      : this.state.step === "details" ? this.copyFor("step_details")
      : this.state.step === "auth" ? this.copyValue.step_auth
      : ""

    // Date is for in-person visits only. Toggling `required` alongside the
    // visibility matters: a hidden required field would block native submit
    // on the copy path.
    const wantsDate = this.state.requestType === "visit"
    this.dateFieldTarget.hidden = !wantsDate
    this.dateInputTarget.required = wantsDate

    // Log-in gate: reflect the confirmation, and flag the checkbox in the
    // attention colour if they tried to send without it.
    this.confirmCheckTarget.checked = this.state.confirmedLogin
    this.loginErrorTarget.hidden = !this.state.loginError
    this.confirmLabelTarget.classList.toggle("fa-visit__confirm--error", this.state.loginError)

    // Item list + empty-state (also toggles the review lede/actions).
    this.renderList()

    // Show the active step, hide the rest.
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
    // When empty, drop the intro line (it contradicts the "nothing selected"
    // message) and the Remove all / Continue actions — leaving just the empty
    // prompt, which points the visitor back to the Select boxes in the guide.
    this.reviewLedeTarget.hidden = this.items.length === 0
    this.reviewFooterTarget.hidden = this.items.length === 0

    this.items.forEach((item) => {
      const li = document.createElement("li")
      li.className = "fa-visit__item"

      const text = document.createElement("div")
      const title = document.createElement("strong")
      title.textContent = item.title
      text.appendChild(title)
      const meta = document.createElement("p")
      meta.className = "fa-visit__meta"
      meta.textContent = this.itemMeta(item) + (item.dates ? " · " + item.dates : "")
      text.appendChild(meta)
      li.appendChild(text)

      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "pl-button"
      remove.textContent = this.copyValue.remove
      remove.setAttribute("aria-label", this.interp(this.copyValue.remove_aria, { title: item.title }))
      remove.dataset.action = "click->request#removeItemButton"
      remove.dataset.requestIdParam = item.id
      li.appendChild(remove)

      this.listTarget.appendChild(li)
    })
  }

  itemMeta(item) {
    return item.container || this.copyValue.no_container
  }

  focusStep() {
    let target
    if (this.state.step === "details") {
      target = this.state.requestType === "visit" ? this.dateInputTarget : this.notesTarget
    } else if (this.state.step === "auth") {
      target = this.authLedeTarget
    } else if (this.state.step === "confirm") {
      target = this.confirmLedeTarget
    } else {
      target = this.dialogTarget
    }
    if (target) target.focus()
  }

  // --- Bar + section counts ---------------------------------------------

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

  // Tally selected items per inventory section and show it in each section's
  // summary heading. The count is of checked descendants, so a series
  // reflects everything across its subseries too. Spans are created lazily
  // on first run; aria-hidden keeps the live-updating number out of the
  // heading's accessible name (the live region carries the spoken feedback).
  refreshSectionCounts() {
    this.inventoryTarget.querySelectorAll("details").forEach((d) => {
      const summary = d.querySelector(":scope > summary")
      if (!summary) return
      // The InventoryComponent pre-renders this span (empty) when requestable;
      // fall back to creating one if it's missing (e.g. older markup).
      let span = summary.querySelector(".fa-visit__section-count")
      if (!span) {
        const heading = summary.querySelector("h3, h4, h5, h6")
        if (!heading) return
        span = document.createElement("span")
        span.className = "fa-visit__section-count fa-small-name"
        span.setAttribute("aria-hidden", "true")
        heading.appendChild(span)
      }
      const n = d.querySelectorAll("[data-fa-request-id]:checked").length
      span.textContent = n ? this.interp(this.copyValue.section_count, { count: n }) : ""
    })
  }

  announce(template, vars) {
    if (this.hasLiveRegionTarget) this.liveRegionTarget.textContent = this.interp(template, vars)
  }

  // --- Helpers -----------------------------------------------------------

  // Minimal %{name} interpolation for i18n-style templates.
  interp(template, vars) {
    return template.replace(/%\{(\w+)\}/g, (_, key) => (vars[key] ?? ""))
  }
}
