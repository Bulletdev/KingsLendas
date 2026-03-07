import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  filter(event) {
    const team = event.currentTarget.dataset.team
    const rows = document.querySelectorAll("[data-champion-row]")

    // Update button styles
    this.element.querySelectorAll("button").forEach(btn => {
      btn.classList.remove("bg-kl-gold", "text-kl-bg")
      btn.classList.add("bg-white/5", "text-gray-300")
    })
    event.currentTarget.classList.add("bg-kl-gold", "text-kl-bg")
    event.currentTarget.classList.remove("bg-white/5", "text-gray-300")

    if (!team) {
      rows.forEach(r => r.style.display = "")
      return
    }

    // Filter champion rows by team picks/bans (requires server-side data attr)
    rows.forEach(r => {
      const teams = r.dataset.teams || ""
      r.style.display = teams.includes(team) ? "" : "none"
    })
  }
}
