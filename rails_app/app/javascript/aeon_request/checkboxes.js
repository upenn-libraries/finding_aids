// Reads and syncs the request checkboxes in the inventory table.

const REQUEST_ID_ATTR = "data-fa-request-id"

export default class RequestCheckboxes {
  constructor(root) {
    this.root = root
  }

  find(id) {
    return this.root.querySelector(`[${REQUEST_ID_ATTR}="${id}"]`)
  }

  readItem(checkbox) {
    const cell = checkbox.closest(".fa-visit__cell")
    return {
      id: checkbox.dataset.faRequestId,
      title: cell.dataset.title,
      dates: cell.dataset.dates,
      container: cell.dataset.container
    }
  }

  setChecked(id, checked) {
    const checkbox = this.find(id)
    if (checkbox) checkbox.checked = checked
  }

  setCheckedFor(items, checked) {
    items.forEach((item) => this.setChecked(item.id, checked))
  }

  tally() {
    return Array.from(this.root.querySelectorAll("details")).map((section) => ({
      section,
      count: section.querySelectorAll(`[${REQUEST_ID_ATTR}]:checked`).length
    }))
  }
}
