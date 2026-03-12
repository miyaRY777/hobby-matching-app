import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["description"]

  toggle(event) {
    const name = event.currentTarget.dataset.name
    const desc = this.descriptionTargets.find(el => el.dataset.name === name)
    if (desc) desc.classList.toggle("hidden")
  }
}
