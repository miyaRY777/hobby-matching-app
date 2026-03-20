import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }
  static targets = ["button"]

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const button = this.buttonTarget
      const originalText = button.textContent
      button.textContent = "Copied!"
      setTimeout(() => {
        button.textContent = originalText
      }, 1500)
    })
  }
}
