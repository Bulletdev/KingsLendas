import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = ["active"]

  filter(event) {
    const group = event.currentTarget.dataset.tabFilterGroupParam

    // Toggle button styles
    this.element.querySelectorAll("button").forEach(btn => {
      btn.classList.remove("bg-kl-gold", "text-kl-bg")
      btn.classList.add("bg-white/5", "text-gray-300")
    })
    event.currentTarget.classList.add("bg-kl-gold", "text-kl-bg")
    event.currentTarget.classList.remove("bg-white/5", "text-gray-300")

    // Show/hide groups
    document.querySelectorAll("[data-tab-group]").forEach(el => {
      if (group === "all" || el.dataset.tabGroup === group) {
        el.style.display = ""
      } else {
        el.style.display = "none"
      }
    })
  }
}
