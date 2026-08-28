import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenField", "chipList", "dropdown", "count"]
  static values = {
    url: String,
    max: { type: Number, default: 10 },
    parentTags: { type: Object, default: {} }
  }

  #debounceTimer = null
  // chips: [{ name, normalized_name, description, parent_tag_id, parent_tag_name }]
  #chips = []
  #activeIndex = -1

  connect() {
    const existing = this.hiddenFieldTarget.value
    if (existing) {
      try {
        const parsed = JSON.parse(existing)
        parsed.forEach(tag => {
          this.#addChip(tag.name, tag.description || "", null, tag.parent_tag_name || null)
        })
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
        const item = items[this.#activeIndex]
        this.#selectExistingTag(item.dataset.name, item.dataset.parentTagName || null)
      } else {
        const q = this.inputTarget.value.trim()
        if (q) this.#confirmNewName(q)
      }
    } else if (event.key === "Escape") {
      this.#closeDropdown()
    }
  }

  selectSuggestion(event) {
    const { name, parentTagName } = event.currentTarget.dataset
    this.#selectExistingTag(name, parentTagName || null)
  }

  confirmNewTagRow() {
    const query = this.inputTarget.value.trim()
    if (query) this.#confirmNewName(query)
  }

  removeChip(event) {
    const name = event.currentTarget.dataset.name
    this.#removeChipByName(name)
  }

  removeTag(event) {
    const { name } = event.detail
    this.#removeChipByName(name)
  }

  #removeChipByName(name) {
    this.#chips = this.#chips.filter(chip => chip.name !== name)
    this.#renderChips()
    this.#syncHiddenField()
    this.#dispatchChipsChanged()
    if (this.#chips.length < this.maxValue) {
      this.inputTarget.disabled = false
    }
  }

  updateDescription(event) {
    const { name, description } = event.detail
    const chip = this.#chips.find(currentChip => currentChip.name === name)

    if (chip) {
      chip.description = description
      this.#syncHiddenField()
    }
  }

  #selectExistingTag(name, parentTagName) {
    this.#addChip(name, "", null, parentTagName || null)
    this.inputTarget.value = ""
    this.#closeDropdown()
  }

  #confirmNewName(query) {
    this.#addChip(query)
    this.inputTarget.value = ""
    this.#closeDropdown()
  }

  #addChip(name, description = "", parentTagId = null, parentTagName = null) {
    const displayName = name.trim()
    const normalizedName = this.#normalizeName(displayName)

    if (!displayName) return
    if (this.#chips.find(chip => chip.normalized_name === normalizedName)) return
    if (this.#chips.length >= this.maxValue) return

    this.#chips.push({
      name: displayName,
      normalized_name: normalizedName,
      description,
      parent_tag_id: parentTagId,
      parent_tag_name: parentTagName
    })
    this.#renderChips()
    this.#syncHiddenField()
    this.#dispatchChipsChanged()

    if (this.#chips.length >= this.maxValue) {
      this.inputTarget.disabled = true
    }
  }

  #renderChips() {
    if (this.hasChipListTarget) {
      this.chipListTarget.innerHTML = ""
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = `${this.#chips.length} / ${this.maxValue}件`
    }
  }

  #syncHiddenField() {
    this.hiddenFieldTarget.value = JSON.stringify(
      this.#chips.map(({ name, description, parent_tag_id }) => ({ name, description, parent_tag_id }))
    )
  }

  #dispatchChipsChanged() {
    this.element.dispatchEvent(new CustomEvent("chips-changed", {
      bubbles: true,
      detail: { chips: [...this.#chips] }
    }))
  }

  async #fetchSuggestions(query) {
    if (this.#chips.find(chip => chip.normalized_name === this.#normalizeName(query))) {
      this.#closeDropdown()
      return
    }

    const url = `${this.urlValue}?q=${encodeURIComponent(query)}`

    try {
      const response = await fetch(url, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
      const hobbies = await response.json()

      if (hobbies.length > 0) {
        this.#renderDropdown(hobbies)
      } else {
        this.#renderNewTagAddRow(query)
      }
    } catch {
      this.#closeDropdown()
    }
  }

  #renderDropdown(hobbies) {
    this.dropdownTarget.innerHTML = hobbies.map(hobby => `
      <li data-testid="autocomplete-item"
          class="autocomplete-item"
          data-name="${this.#escapeHtml(hobby.name)}"
          data-parent-tag-name="${this.#escapeHtml(hobby.parent_tag_name || "")}"
          data-action="click->tag-autocomplete#selectSuggestion">
        <span>${this.#escapeHtml(hobby.name)}</span>
        ${hobby.parent_tag_name
          ? `<span data-testid="autocomplete-badge" class="autocomplete-badge">${this.#escapeHtml(hobby.parent_tag_name)}</span>`
          : ""}
      </li>
    `).join("")
    this.dropdownTarget.classList.remove("hidden")
  }

  #renderNewTagAddRow(query) {
    this.dropdownTarget.innerHTML = `
      <li data-testid="new-tag-add-row"
          class="autocomplete-item"
          data-action="click->tag-autocomplete#confirmNewTagRow">
        「${this.#escapeHtml(query)}」を新しいタグとして追加
      </li>
    `
    this.dropdownTarget.classList.remove("hidden")
  }

  #closeDropdown() {
    this.dropdownTarget.innerHTML = ""
    this.dropdownTarget.classList.add("hidden")
    this.#activeIndex = -1
  }

  #updateActiveItem(items) {
    items.forEach((item, index) => {
      item.style.background = index === this.#activeIndex ? "rgba(96,165,250,0.15)" : "transparent"
    })
  }

  #escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }

  #normalizeName(value) {
    return String(value).normalize("NFKC").trim().toLowerCase()
  }
}
