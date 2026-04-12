import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenField", "chipList", "dropdown", "count"]
  static values = {
    url: String,
    max: { type: Number, default: 10 }
  }

  #debounceTimer = null
  // chips: [{ name: String, description: String }]
  #chips = []
  #activeIndex = -1

  connect() {
    const existing = this.hiddenFieldTarget.value
    if (existing) {
      try {
        const parsed = JSON.parse(existing)
        parsed.forEach(tag => this.#addChip(tag.name, tag.description || ""))
      } catch {
        // JSON でない場合は無視
      }
    }
  }

  onInput() {
    clearTimeout(this.#debounceTimer)
    const q = this.inputTarget.value.trim()
    if (q.length < 2) {
      this.#closeDropdown()
      return
    }
    this.#debounceTimer = setTimeout(() => this.#fetchSuggestions(q), 300)
  }

  onKeydown(event) {
    const items = this.dropdownTarget.querySelectorAll("[data-testid='autocomplete-item']")
    const isOpen = !this.dropdownTarget.classList.contains("hidden") && items.length > 0

    if (event.key === "ArrowDown") {
      event.preventDefault()
      if (!isOpen) return
      this.#activeIndex = Math.min(this.#activeIndex + 1, items.length - 1)
      this.#updateActiveItem(items)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      if (!isOpen) return
      this.#activeIndex = Math.max(this.#activeIndex - 1, -1)
      this.#updateActiveItem(items)
    } else if (event.key === "Enter") {
      event.preventDefault()
      if (isOpen && this.#activeIndex >= 0) {
        const name = items[this.#activeIndex].dataset.name
        this.#addChip(name, "")
        this.inputTarget.value = ""
        this.#closeDropdown()
      } else {
        const q = this.inputTarget.value.trim()
        if (q) {
          this.#addChip(q, "")
          this.inputTarget.value = ""
          this.#closeDropdown()
        }
      }
    } else if (event.key === "Escape") {
      this.#closeDropdown()
    }
  }

  selectSuggestion(event) {
    const name = event.currentTarget.dataset.name
    this.#addChip(name, "")
    this.inputTarget.value = ""
    this.#closeDropdown()
  }

  removeChip(event) {
    const name = event.currentTarget.dataset.name
    this.#chips = this.#chips.filter(c => c.name !== name)
    this.#renderChips()
    this.#syncHiddenField()
    this.#dispatchChipsChanged()
    if (this.#chips.length < this.maxValue) {
      this.inputTarget.disabled = false
    }
  }

  // tag-description コントローラから説明文更新を受け取る
  updateDescription(event) {
    const { name, description } = event.detail
    const chip = this.#chips.find(c => c.name === name)
    if (chip) {
      chip.description = description
      this.#syncHiddenField()
    }
  }

  // private

  #addChip(name, description = "") {
    const normalized = name.toLowerCase()
    if (this.#chips.find(c => c.name === normalized)) return
    if (this.#chips.length >= this.maxValue) return
    this.#chips.push({ name: normalized, description })
    this.#renderChips()
    this.#syncHiddenField()
    this.#dispatchChipsChanged()
    if (this.#chips.length >= this.maxValue) {
      this.inputTarget.disabled = true
    }
  }

  #renderChips() {
    this.chipListTarget.innerHTML = this.#chips.map(chip => `
      <span data-testid="chip"
            style="display: inline-flex; align-items: center; gap: 0.25rem; border-radius: 9999px; background: rgba(96, 165, 250, 0.15); padding: 0.25rem 0.75rem; font-size: 0.875rem; color: #60a5fa;">
        ${this.#escapeHtml(chip.name)}
        <button type="button"
                data-action="click->tag-autocomplete#removeChip"
                data-name="${this.#escapeHtml(chip.name)}"
                style="margin-left: 0.25rem; color: #60a5fa; background: none; border: none; cursor: pointer; line-height: 1;"
                aria-label="${this.#escapeHtml(chip.name)}を削除">×</button>
      </span>
    `).join("")

    if (this.hasCountTarget) {
      this.countTarget.textContent = `${this.#chips.length} / ${this.maxValue}件`
    }
  }

  #syncHiddenField() {
    this.hiddenFieldTarget.value = JSON.stringify(this.#chips)
  }

  #dispatchChipsChanged() {
    this.element.dispatchEvent(new CustomEvent("chips-changed", {
      bubbles: true,
      detail: { chips: [...this.#chips] }
    }))
  }

  async #fetchSuggestions(q) {
    const url = `${this.urlValue}?q=${encodeURIComponent(q)}`
    try {
      const res = await fetch(url, {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
      const names = await res.json()
      this.#renderDropdown(names)
    } catch {
      this.#closeDropdown()
    }
  }

  #renderDropdown(names) {
    if (names.length === 0) {
      this.#closeDropdown()
      return
    }
    this.dropdownTarget.innerHTML = names.map(name => `
      <li data-testid="autocomplete-item"
          data-name="${this.#escapeHtml(name)}"
          data-action="click->tag-autocomplete#selectSuggestion"
          style="cursor: pointer; padding: 0.5rem 1rem; font-size: 0.875rem; color: #d1d5db; transition: background 0.15s;"
          onmouseenter="this.style.background='rgba(96, 165, 250, 0.15)'"
          onmouseleave="this.style.background='transparent'">
        ${this.#escapeHtml(name)}
      </li>
    `).join("")
    this.dropdownTarget.classList.remove("hidden")
  }

  #closeDropdown() {
    this.dropdownTarget.innerHTML = ""
    this.dropdownTarget.classList.add("hidden")
    this.#activeIndex = -1
  }

  #updateActiveItem(items) {
    items.forEach((item, i) => {
      if (i === this.#activeIndex) {
        item.style.background = "rgba(96, 165, 250, 0.15)"
      } else {
        item.style.background = "transparent"
      }
    })
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
