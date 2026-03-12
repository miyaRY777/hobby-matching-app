import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  onChipsChanged(event) {
    const { chips } = event.detail
    this.#renderDescriptionInputs(chips)
  }

  onDescriptionInput(event) {
    const name = event.currentTarget.dataset.name
    const description = event.currentTarget.value
    this.element.dispatchEvent(new CustomEvent("tag-description-update", {
      bubbles: true,
      detail: { name, description }
    }))
  }

  // private

  #renderDescriptionInputs(chips) {
    if (!this.hasContainerTarget) return
    if (!chips || chips.length === 0) {
      this.containerTarget.innerHTML = ""
      return
    }
    this.containerTarget.innerHTML = chips.map(chip => `
      <div class="mt-2">
        <label class="block text-xs font-medium text-gray-500 mb-1">
          ${this.#escapeHtml(chip.name)} の説明（任意・200字以内）
        </label>
        <input type="text"
               data-testid="description-input"
               data-name="${this.#escapeHtml(chip.name)}"
               data-action="input->tag-description#onDescriptionInput"
               value="${this.#escapeHtml(chip.description || "")}"
               placeholder="例：毎日プレイしています"
               maxlength="200"
               class="w-full rounded-lg border border-gray-300 px-3 py-1.5 text-sm text-gray-800
                      focus:border-blue-500 focus:ring-2 focus:ring-blue-200 focus:outline-none">
      </div>
    `).join("")
  }

  #escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }
}
