import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  onChipsChanged(event) {
    const { chips } = event.detail
    this.#renderDescriptionInputs(chips)
  }

  onToggle(event) {
    const button = event.currentTarget
    const content = button.closest("[data-testid='tag-card']")
                          ?.querySelector("[data-description-content]")
    if (!content) return
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

  onRemove(event) {
    const name = event.currentTarget.dataset.name

    this.element.dispatchEvent(new CustomEvent("tag-remove-request", {
      bubbles: true,
      detail: { name }
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
      <div data-testid="tag-card"
           class="rounded-2xl border border-slate-700/60 bg-slate-900/65 shadow-[inset_0_1px_0_rgba(255,255,255,0.03)]">
        <div class="rounded-2xl px-4 py-2.5 transition hover:bg-white/5">
          <div style="display:flex;align-items:center;justify-content:space-between;gap:0.75rem;">
            <div style="display:flex;align-items:center;gap:0.6rem;min-width:0;flex:1;">
              <span class="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-blue-500/15">
                <img src="/icon.png?v=2" alt="" class="h-5 w-5 rounded-md object-cover">
              </span>
              <div style="display:flex;align-items:center;gap:0.35rem;min-width:0;flex:1;flex-wrap:wrap;">
                <span data-testid="tag-parent-label"
                      class="inline-flex items-center rounded-full px-2.5 text-[11px] font-semibold"
                      style="${this.#parentLabelStyle(chip.parent_tag_name)}">${this.#escapeHtml(chip.parent_tag_name || "未分類")}</span>
                <span data-testid="tag-child-chip"
                      class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                      style="background:rgba(59,130,246,0.14);color:#bfdbfe;border:1px solid rgba(96,165,250,0.24);">${this.#escapeHtml(chip.name)}</span>
                <button type="button"
                        data-testid="tag-remove-button"
                        data-name="${this.#escapeHtml(chip.name)}"
                        data-action="click->tag-description#onRemove"
                        class="inline-flex h-5 w-5 items-center justify-center rounded-full text-[10px] leading-none transition"
                        style="display:inline-flex;align-items:center;justify-content:center;width:1.25rem;height:1.25rem;border:1px solid rgba(148,163,184,0.5);background:#0f172a;color:#cbd5e1;border-radius:9999px;"
                        aria-label="${this.#escapeHtml(chip.name)}を削除">×</button>
              </div>
            </div>
            <button type="button"
                    data-action="click->tag-description#onToggle"
                    data-testid="description-toggle"
                    class="shrink-0 border-none cursor-pointer"
                    style="display:inline-flex;align-items:center;justify-content:center;white-space:nowrap;line-height:1.2;padding:0.35rem 0.7rem;border-radius:9999px;background:rgba(59,130,246,0.14);color:#bfdbfe;border:1px solid rgba(96,165,250,0.22);font-size:0.75rem;font-weight:600;">説明を追加</button>
          </div>
        </div>
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

  #parentLabelStyle(parentTagName) {
    if (parentTagName) {
      return "background:linear-gradient(135deg, rgba(244,63,94,0.24), rgba(236,72,153,0.18));color:#fecdd3;border:1px solid rgba(251,113,133,0.38);padding-top:0.18rem;padding-bottom:0.18rem;"
    }

    return "background:rgba(71,85,105,0.22);color:#cbd5e1;border:1px solid rgba(148,163,184,0.28);padding-top:0.18rem;padding-bottom:0.18rem;"
  }
}
