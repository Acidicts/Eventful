import { Controller } from "@hotwired/stimulus"

// simple debounce helper
function debounce(fn, delay) {
  let timer
  return function(...args) {
    clearTimeout(timer)
    timer = setTimeout(() => fn.apply(this, args), delay)
  }
}

export default class extends Controller {
  connect() {
    // decide which provider to use: if we have a Google key, use the new HTTP API;
    // otherwise fall back to Nominatim.  (We keep the old maps script support too
    // for legacy reasons, but it's not required.)
    const keyMeta = document.querySelector('meta[name="google-maps-api-key"]')
    const googleKey = keyMeta && keyMeta.content ? keyMeta.content.trim() : ''

    console.debug("LocationAutocompleteController connect, googleKey=", googleKey)

    if (googleKey) {
      this.googleKey = googleKey
      this.initializeGoogleNew()
    } else {
      this.initializeNominatim()
    }
  }

  // legacy Maps JavaScript widget; kept for compatibility but not used when
  // we have a key and prefer the new HTTP endpoint.
  initializeGoogle() {
    if (window.google && window.google.maps && window.google.maps.places) {
      this.autocomplete = new google.maps.places.Autocomplete(this.element, { types: ['geocode'] })
      this.autocomplete.setFields(['formatted_address'])
      this.autocomplete.addListener('place_changed', () => {
        const place = this.autocomplete.getPlace()
        if (place && place.formatted_address) {
          this.element.value = place.formatted_address
        }
      })
    }
  }

  initializeNominatim() {
    // ensure a <datalist> exists for suggestions
    this.list = document.getElementById('location-results')
    this.element.addEventListener('input', debounce(() => this.fetchSuggestions(), 300))
  }

  // new HTTP-based Google Autocomplete (v1/places:autocomplete)
  initializeGoogleNew() {
    this.list = document.getElementById('location-results')
    this.element.addEventListener('input', debounce(() => this.fetchGoogle(), 300))
  }

  async fetchGoogle() {
    const query = this.element.value.trim()
    if (!query) {
      this.clearList()
      return
    }

    console.debug("fetchGoogle input=", query)
    const body = { input: query }
    try {
      const res = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': this.googleKey
        },
        body: JSON.stringify(body)
      })
      console.debug("fetchGoogle response status", res.status)
      const data = await res.json()
      console.debug("fetchGoogle data", data)
      this.updateGoogleList(data)
    } catch (e) {
      console.error('Google autocomplete failed', e)
    }
  }

  updateGoogleList(data) {
    if (!this.list || !data || !Array.isArray(data.suggestions)) return
    this.list.innerHTML = ''
    data.suggestions.slice(0, 5).forEach(s => {
      const text = s.placePrediction?.text?.text || s.queryPrediction?.text?.text
      if (text) {
        const opt = document.createElement('option')
        opt.value = text
        this.list.appendChild(opt)
      }
    })
  }

  async fetchSuggestions() {
    const query = this.element.value.trim()
    if (!query) {
      this.clearList()
      return
    }
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}`,
        { headers: { 'Accept': 'application/json' } }
      )
      const data = await res.json()
      this.updateList(data)
    } catch (e) {
      console.error('Nominatim lookup failed', e)
    }
  }

  updateList(results) {
    if (!this.list) return
    this.list.innerHTML = ''
    results.slice(0, 5).forEach(place => {
      const opt = document.createElement('option')
      opt.value = place.display_name
      this.list.appendChild(opt)
    })
  }

  clearList() {
    if (this.list) this.list.innerHTML = ''
  }
}