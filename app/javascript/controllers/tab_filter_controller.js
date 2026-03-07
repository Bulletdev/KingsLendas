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
    const group = event.currentTarget.dataset.tabFilterGroupParam

    this.element.querySelectorAll("button").forEach(setInactive)
    setActive(event.currentTarget)

    document.querySelectorAll("[data-tab-group]").forEach(el => {
      el.style.display = (group === "all" || el.dataset.tabGroup === group) ? "" : "none"
    })
  }
}
