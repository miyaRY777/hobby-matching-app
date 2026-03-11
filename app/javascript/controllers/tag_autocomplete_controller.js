import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenField", "chipList", "dropdown"]
  static values = {
    url: String,
    max: { type: Number, default: 10 }
  }

  #debounceTimer = null
  #chips = []
  #activeIndex = -1

  connect() {
    const existing = this.hiddenFieldTarget.value
    if (existing) {
      existing.split(",").map(s => s.trim()).filter(Boolean).forEach(name => {
        this.#addChip(name)
      })
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
        this.#addChip(name)
        this.inputTarget.value = ""
        this.#closeDropdown()
      } else {
        const q = this.inputTarget.value.trim()
        if (q) {
          this.#addChip(q)
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
    this.#addChip(name)
    this.inputTarget.value = ""
    this.#closeDropdown()
  }

  removeChip(event) {
    const name = event.currentTarget.dataset.name
    this.#chips = this.#chips.filter(c => c !== name)
    this.#renderChips()
    this.#syncHiddenField()
    if (this.#chips.length < this.maxValue) {
      this.inputTarget.disabled = false
    }
  }

  // private

  #addChip(name) {
    const normalized = name.toLowerCase()
    if (this.#chips.includes(normalized)) return
    if (this.#chips.length >= this.maxValue) return
    this.#chips.push(normalized)
    this.#renderChips()
    this.#syncHiddenField()
    if (this.#chips.length >= this.maxValue) {
      this.inputTarget.disabled = true
    }
  }

  #renderChips() {
    this.chipListTarget.innerHTML = this.#chips.map(name => `
      <span data-testid="chip"
            class="inline-flex items-center gap-1 rounded-full bg-blue-100 px-3 py-1 text-sm text-blue-800">
        ${this.#escapeHtml(name)}
        <button type="button"
                data-action="click->tag-autocomplete#removeChip"
                data-name="${this.#escapeHtml(name)}"
                class="ml-1 text-blue-500 hover:text-blue-700 leading-none"
                aria-label="${this.#escapeHtml(name)}を削除">×</button>
      </span>
    `).join("")
  }

  #syncHiddenField() {
    this.hiddenFieldTarget.value = this.#chips.join(",")
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
          class="cursor-pointer px-4 py-2 hover:bg-blue-50 text-sm text-gray-800">
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
        item.classList.add("bg-blue-100")
        item.classList.remove("hover:bg-blue-50")
      } else {
        item.classList.remove("bg-blue-100")
        item.classList.add("hover:bg-blue-50")
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
