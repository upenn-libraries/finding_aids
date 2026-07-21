import { Controller } from "@hotwired/stimulus"

const DEFAULT_CENTER = [39.98, -75.19]
const DEFAULT_ZOOM = 11

// Leaflet map controller for the regional-partnership band.
// Repository data is fetched from /api/map_data (cached server-side).
//
// An AbortController is wired to disconnect() so in-flight fetch requests
// are cancelled when the Stimulus controller is torn down — for example
// during a Turbo back-navigation away from the homepage.
export default class extends Controller {
  connect() {
    if (typeof L === 'undefined') {
      console.warn('Leaflet library not loaded — map cannot render')
      return
    }
    this.abortController = new AbortController()
    this._initMap()
    this._loadTileLayer()
    this._loadMarkers()
  }

  disconnect() {
    this.abortController?.abort()
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  _initMap() {
    this.map = L.map(this.element, {
      scrollWheelZoom: false
    }).setView(DEFAULT_CENTER, DEFAULT_ZOOM)
  }

  _loadTileLayer() {
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)
  }

  async _loadMarkers() {
    try {
      const response = await fetch('/api/map_data', { signal: this.abortController.signal })
      if (!response.ok) return
      const repos = await response.json()
      if (this.abortController?.signal.aborted) return
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
  return `<strong>${name}</strong><br />${count} guides<br /><a href="${repo.records_url}">View all records</a>`
}
