import { Controller } from "@hotwired/stimulus"


// Leaflet map controller for the regional-partnership band.
// Repository data comes from data-map-repos-value attribute set in _regional_partnership.html.erb.
export default class extends Controller {
  static values = { repos: Array }

  connect() {
    if (!this.reposValue || this.reposValue.length === 0) return

    this.map = L.map(this.element, {
      scrollWheelZoom: false
    }).setView([39.98, -75.19], 11)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    this.reposValue.forEach((repo) => {
      if (repo.lat && repo.lng) {
        const content =
          '<strong>' + this._escapeHtml(repo.name) + '</strong><br />' +
          Number(repo.count).toLocaleString() + ' guides'

        L.marker([repo.lat, repo.lng])
          .addTo(this.map)
          .bindPopup(content)
      }
    })
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  _escapeHtml(str) {
    const div = document.createElement('div')
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  }
}
