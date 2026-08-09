import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  submitPastedLink(event) {
    const sourceUrl = event.clipboardData?.getData("text/plain")?.trim()

    if (!this.validLink(sourceUrl)) return

    event.preventDefault()
    this.linkTarget.value = sourceUrl
    this.element.requestSubmit()
  }

  validLink(value) {
    try {
      const url = new URL(value)
      return ["http:", "https:"].includes(url.protocol)
    } catch {
      return false
    }
  }
}
