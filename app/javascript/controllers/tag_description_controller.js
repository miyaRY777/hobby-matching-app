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
      <div style="margin-top: 0.75rem; border-radius: 0.5rem; border: 1px solid rgba(55, 65, 81, 0.6); background: rgba(255,255,255,0.05); padding: 0.75rem 1rem;">
        <label style="display: block; font-size: 0.875rem; font-weight: 600; color: #60a5fa; margin-bottom: 0.25rem;">
          # ${this.#escapeHtml(chip.name)}
          <span style="margin-left: 0.25rem; font-size: 0.75rem; font-weight: 400; color: #6b7280;">の説明（任意・200字以内）</span>
        </label>
        <textarea data-testid="description-input"
                  data-name="${this.#escapeHtml(chip.name)}"
                  data-action="input->tag-description#onDescriptionInput"
                  placeholder="例：\nマイクラ歴3年で、建築メインで遊んでいます！最近はサバイバルモードにハマっています。"
                  maxlength="200"
                  rows="3"
                  style="width: 100%; border-radius: 0.5rem; border: 1px solid rgba(55, 65, 81, 0.6); background: rgba(255,255,255,0.05); color: #ffffff; padding: 0.5rem 0.75rem; font-size: 0.875rem; outline: none; resize: none; box-sizing: border-box;">${this.#escapeHtml(chip.description || "")}</textarea>
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
