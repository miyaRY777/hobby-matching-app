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
      <div class="rounded-2xl border border-slate-700/60 bg-slate-900/65 shadow-[inset_0_1px_0_rgba(255,255,255,0.03)]">
        <button type="button"
                data-action="click->tag-description#onToggle"
                data-testid="description-toggle"
                class="flex w-full items-center justify-between gap-3 rounded-2xl px-4 py-3 text-left transition hover:bg-white/5">
          <span class="flex min-w-0 items-center gap-3">
            <span class="inline-flex h-9 w-9 items-center justify-center rounded-full bg-blue-500/15 text-base text-blue-300">✏️</span>
            <span class="min-w-0">
              <span class="block truncate text-sm font-semibold text-slate-100">${this.#escapeHtml(chip.name)}</span>
              <span class="mt-0.5 block text-xs text-slate-400">その趣味との関わり方や最近ハマっていることを書けます</span>
            </span>
          </span>
          <span class="shrink-0 text-xs font-medium text-blue-300">説明を追加</span>
        </button>
        <div data-description-content class="hidden border-t border-slate-700/60 px-4 pb-4 pt-4">
          <textarea data-testid="description-input"
                    data-name="${this.#escapeHtml(chip.name)}"
                    data-action="input->tag-description#onDescriptionInput"
                    placeholder="例：マイクラ歴3年で、建築メインで遊んでいます！"
                    maxlength="200"
                    rows="3"
                    class="w-full rounded-2xl border border-slate-700/70 bg-slate-950/70 px-4 py-3 text-sm leading-7 text-white outline-none resize-none box-border transition placeholder:text-slate-500 focus:border-blue-400/70 focus:ring-2 focus:ring-blue-500/20">${this.#escapeHtml(chip.description || "")}</textarea>
          <div data-testid="description-counter"
               class="mt-2 text-right text-xs font-medium tracking-wide text-slate-500">${(chip.description || "").length} / 200字</div>
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
