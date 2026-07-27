// Persists request selections to localStorage, keyed per collection.

const VERSION = 1

export default class RequestStorage {
  constructor(key) {
    this.key = key
  }

  read() {
    try {
      const stored = JSON.parse(localStorage.getItem(this.key))
      if (stored?.version === VERSION && Array.isArray(stored.items)) return stored.items
    } catch (error) {
      console.warn("RequestStorage: read failed", error)
    }
    return []
  }

  write(items) {
    try {
      localStorage.setItem(this.key, JSON.stringify({ version: VERSION, items }))
    } catch (error) {
      console.warn("RequestStorage: write failed", error)
    }
  }

  clear() {
    try {
      localStorage.removeItem(this.key)
    } catch (error) {
      console.warn("RequestStorage: clear failed", error)
    }
  }
}
