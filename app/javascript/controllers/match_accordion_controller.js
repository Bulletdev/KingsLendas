import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  toggle(event) {
    if (event.target.closest("a, button")) return

    const opening = this.contentTarget.classList.contains("hidden")

    // Close all other open accordions
    if (opening) {
      document.querySelectorAll("[data-controller~='match-accordion']").forEach(el => {
        if (el === this.element) return
        const content = el.querySelector("[data-match-accordion-target='content']")
        const icon    = el.querySelector("[data-match-accordion-target='icon']")
        if (content && !content.classList.contains("hidden")) {
          content.classList.add("hidden")
          if (icon) icon.textContent = "▼"
        }
      })
    }

    const isHidden = this.contentTarget.classList.toggle("hidden")
    if (this.hasIconTarget) {
      this.iconTarget.textContent = isHidden ? "▼" : "▲"
    }

    // Lazy load turbo frame on first expand
    if (!isHidden) {
      this.contentTarget.querySelectorAll("turbo-frame[data-lazy-src]").forEach(frame => {
        if (!frame.src) frame.src = frame.dataset.lazySrc
      })
    }
  }
}
