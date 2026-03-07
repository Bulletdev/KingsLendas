import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  tick() {
    const targetTime = new Date(this.targetValue + " UTC")
    const now = new Date()
    const diff = targetTime - now

    if (diff <= 0) {
      this.element.innerHTML = '<span class="text-red-400 animate-pulse font-bold">AO VIVO!</span>'
      clearInterval(this.timer)
      return
    }

    const d = Math.floor(diff / 86400000)
    const h = Math.floor((diff % 86400000) / 3600000)
    const m = Math.floor((diff % 3600000) / 60000)
    const s = Math.floor((diff % 60000) / 1000)

    if (d > 0) {
      this.element.textContent = `${d}d ${h}h ${m}m`
    } else {
      this.element.textContent = `${h}h ${m}m ${s}s`
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
