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
      if (!response.ok) {
        this._showError()
        return
      }
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
      this._showError()
    }
  }

  _showError() {
    this.element.textContent = 'Map data could not be loaded.'
    this.element.style.display = 'flex'
    this.element.style.alignItems = 'center'
    this.element.style.justifyContent = 'center'
  }
}

const _escapeDiv = document.createElement('div')

function escapeHtml(str) {
  _escapeDiv.textContent = str
  return _escapeDiv.innerHTML
}

function markerContent(repo) {
  const name = escapeHtml(repo.name)
  const count = Number(repo.count).toLocaleString()
  return `<strong>${name}</strong><br />${count} guides`
}
