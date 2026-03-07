import { Controller } from "@hotwired/stimulus"

function setInactive(btn) {
  btn.style.borderColor = "rgba(255,255,255,0.15)"
  btn.style.background  = "transparent"
  btn.style.color       = "rgba(255,255,255,0.45)"
}

function setActive(btn) {
  btn.style.borderColor = "var(--retro-gold)"
  btn.style.background  = "rgba(200,155,60,0.15)"
  btn.style.color       = "var(--retro-gold)"
}

export default class extends Controller {
  filter(event) {
    const team = event.currentTarget.dataset.team
    const rows = document.querySelectorAll("[data-champion-row]")

    this.element.querySelectorAll("button").forEach(setInactive)
    setActive(event.currentTarget)

    if (team === "") {
      rows.forEach(r => r.style.display = "")
      return
    }

    rows.forEach(r => {
      const teams = r.dataset.teams || ""
      r.style.display = teams.split(",").includes(team) ? "" : "none"
    })
  }
}
