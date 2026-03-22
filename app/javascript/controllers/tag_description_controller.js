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
      <div class="mt-3 rounded-lg border border-gray-200 bg-gray-50 px-4 py-3">
        <label class="block text-sm font-semibold text-blue-700 mb-1">
          # ${this.#escapeHtml(chip.name)}
          <span class="ml-1 text-xs font-normal text-gray-400">の説明（任意・200字以内）</span>
        </label>
        <textarea data-testid="description-input"
                  data-name="${this.#escapeHtml(chip.name)}"
                  data-action="input->tag-description#onDescriptionInput"
                  placeholder="例：\nマイクラ歴3年で、建築メインで遊んでいます！最近はサバイバルモードにハマっています。"
                  maxlength="200"
                  rows="3"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-800
                         focus:border-blue-500 focus:ring-2 focus:ring-blue-200 focus:outline-none
                         resize-none bg-white">${this.#escapeHtml(chip.description || "")}</textarea>
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
