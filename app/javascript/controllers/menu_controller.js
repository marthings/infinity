import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    const isOpen = this.buttonTarget.getAttribute("aria-expanded") === "true"

    this.setOpen(!isOpen)
  }

  close(event) {
    if (event.key !== "Escape" || this.menuTarget.hidden) return

    this.setOpen(false)
    this.buttonTarget.focus()
  }

  setOpen(isOpen) {
    this.buttonTarget.setAttribute("aria-expanded", isOpen)
    this.buttonTarget.setAttribute("aria-label", isOpen ? "Close navigation" : "Open navigation")
    this.menuTarget.hidden = !isOpen
  }
}
