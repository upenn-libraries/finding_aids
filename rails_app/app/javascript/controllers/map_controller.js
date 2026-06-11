import { Controller } from "@hotwired/stimulus"


// Leaflet map controller for the regional-partnership band.
// Repository data comes from data-map-repos-value attribute set in _regional_partnership.html.erb.
export default class extends Controller {
  static values = { repos: Array }

  connect() {
    if (!this.reposValue || this.reposValue.length === 0) return

    this._initMap()
    this._addTileLayer()
    this._addMarkers()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  _initMap() {
    this.map = L.map(this.element, {
      scrollWheelZoom: false
    }).setView([39.98, -75.19], 11)
  }

  _addTileLayer() {
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)
  }

  _addMarkers() {
    this.reposValue.forEach((repo) => {
      if (repo.lat && repo.lng) {
        L.marker([repo.lat, repo.lng])
          .addTo(this.map)
          .bindPopup(markerContent(repo))
      }
    })
  }
}

function escapeHtml(str) {
  const div = document.createElement('div')
  div.appendChild(document.createTextNode(str))
  return div.innerHTML
}

function markerContent(repo) {
  const name = escapeHtml(repo.name)
  const count = Number(repo.count).toLocaleString()
  return `<strong>${name}</strong><br />${count} guides`
}
