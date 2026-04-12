import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "openText", "closeText"]

  connect() {
    this.contentTarget.classList.add("hidden")
  }

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.openTextTarget.classList.toggle("hidden")
    this.closeTextTarget.classList.toggle("hidden")
  }
}
