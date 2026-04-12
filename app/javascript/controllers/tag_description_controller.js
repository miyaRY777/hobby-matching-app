import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  onChipsChanged(event) {
    const { chips } = event.detail
    this.#renderDescriptionInputs(chips)
  }

  onToggle(event) {
    const button = event.currentTarget
    const content = button.nextElementSibling
    content.classList.toggle("hidden")
  }

  onDescriptionInput(event) {
    const textarea = event.currentTarget
    const name = textarea.dataset.name
    const description = textarea.value

    // カウンター更新
    const counter = textarea.closest("[data-description-content]")
                            ?.querySelector("[data-testid='description-counter']")
    if (counter) {
      counter.textContent = `${description.length} / 200字`
    }

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
      <div class="mt-3 rounded-lg border border-slate-700/60 bg-white/5">
        <button type="button"
                data-action="click->tag-description#onToggle"
                data-testid="description-toggle"
                class="flex w-full items-center gap-2 px-3 py-2 text-left text-sm font-semibold text-blue-400 hover:bg-white/5 rounded-lg">
          <span>${this.#escapeHtml(chip.name)}</span>
          <span class="text-xs text-gray-400">✏️ 説明を追加</span>
        </button>
        <div data-description-content class="hidden px-3 pb-3">
          <textarea data-testid="description-input"
                    data-name="${this.#escapeHtml(chip.name)}"
                    data-action="input->tag-description#onDescriptionInput"
                    placeholder="例：マイクラ歴3年で、建築メインで遊んでいます！"
                    maxlength="200"
                    rows="3"
                    class="w-full rounded-md border border-slate-700/60 bg-white/5 px-3 py-2 text-sm text-white outline-none resize-none box-border">${this.#escapeHtml(chip.description || "")}</textarea>
          <div data-testid="description-counter"
               class="mt-1 text-right text-xs text-gray-500">${(chip.description || "").length} / 200字</div>
        </div>
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
