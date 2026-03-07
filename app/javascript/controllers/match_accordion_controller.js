import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  toggle(event) {
    // Don't toggle if clicking links inside
    if (event.target.closest("a, button")) return

    const isHidden = this.contentTarget.classList.toggle("hidden")
    if (this.hasIconTarget) {
      this.iconTarget.textContent = isHidden ? "▼" : "▲"
    }

    // Lazy load turbo frame if first expand
    if (!isHidden) {
      const frame = this.contentTarget.querySelector("turbo-frame[data-lazy-src]")
      if (frame && !frame.src) {
        frame.src = frame.dataset.lazySrc
      }
    }
  }
}
