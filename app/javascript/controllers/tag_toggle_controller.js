import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tag", "description", "panel"]

  connect() {
    const firstTag = this.tagTargets[0]
    if (firstTag && this.hasPanelTarget) {
      this.#openTag(firstTag)
    }
  }

  toggle(event) {
    // 全タグを非アクティブに戻す
    this.tagTargets.forEach(tag => {
      tag.dataset.active = "false"
      tag.classList.remove("bg-blue-600", "text-white")
      tag.classList.add("bg-blue-100", "text-blue-800")
    })

    this.#openTag(event.currentTarget)
  }

  // private

  #openTag(tagEl) {
    const name = tagEl.dataset.name
    tagEl.dataset.active = "true"
    tagEl.classList.remove("bg-blue-100", "text-blue-800")
    tagEl.classList.add("bg-blue-600", "text-white")

    const desc = this.descriptionTargets.find(el => el.dataset.name === name)
    this.panelTarget.textContent = desc ? desc.textContent.trim() : ""
    this.panelTarget.classList.remove("hidden")
  }
}
