import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  close() {
    this.panelTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  closeOnSuccess(event) {
    if (event.detail.success) this.close()
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }
}
