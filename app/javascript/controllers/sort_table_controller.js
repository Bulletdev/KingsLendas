import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { direction: String }

  connect() {
    this.directionValue = "asc"
    this.sortCol = null
  }

  sort(event) {
    const th = event.currentTarget
    const colIdx = parseInt(th.dataset.sortCol)

    if (this.sortCol === colIdx) {
      this.directionValue = this.directionValue === "asc" ? "desc" : "asc"
    } else {
      this.sortCol = colIdx
      this.directionValue = "desc"
    }

    // Update header arrows
    this.element.querySelectorAll("th[data-sort-col]").forEach(el => {
      el.textContent = el.textContent.replace(/[↑↓]/, "").trim()
    })
    th.textContent = th.textContent + (this.directionValue === "asc" ? " ↑" : " ↓")

    const tbody = this.element.querySelector("tbody")
    if (!tbody) return

    const rows = Array.from(tbody.querySelectorAll("tr"))
    rows.sort((a, b) => {
      const aVal = a.cells[colIdx]?.textContent.trim() || ""
      const bVal = b.cells[colIdx]?.textContent.trim() || ""
      const aNum = parseFloat(aVal)
      const bNum = parseFloat(bVal)

      let cmp
      if (!isNaN(aNum) && !isNaN(bNum)) {
        cmp = aNum - bNum
      } else {
        cmp = aVal.localeCompare(bVal, "pt-BR")
      }

      return this.directionValue === "asc" ? cmp : -cmp
    })

    rows.forEach(row => tbody.appendChild(row))
  }
}
