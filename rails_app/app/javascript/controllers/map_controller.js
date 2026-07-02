import { Controller } from "@hotwired/stimulus"


// Leaflet map controller for the regional-partnership band.
// Repository data is fetched from /api/map_data (cached server-side).
export default class extends Controller {
  connect() {
    this._initMap()
    this._addTileLayer()
    this._loadMarkers()
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

  async _loadMarkers() {
    try {
      const response = await fetch('/api/map_data')
      if (!response.ok) return
      const repos = await response.json()
      repos.forEach((repo) => {
        if (repo.lat && repo.lng) {
          L.marker([repo.lat, repo.lng])
            .addTo(this.map)
            .bindPopup(markerContent(repo))
        }
      })
    } catch (e) {
      console.error('Failed to load map data:', e)
    }
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
  const recordsUrl = repo.records_url || `/records?f[repository_ssi][]=${encodeURIComponent(name)}`
  return `<strong>${name}</strong><br />${count} guides<br /><a href="${recordsUrl}">View all records</a>`
}
