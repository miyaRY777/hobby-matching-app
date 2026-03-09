import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "mode"]

  connect() {
    this._debounceTimer = null
  }

  // テキスト入力時に debounce 経由でサブミット
  search() {
    clearTimeout(this._debounceTimer)
    this._debounceTimer = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300)
  }

  // AND/OR トグルボタン押下時
  setMode(event) {
    event.preventDefault()
    const mode = event.params.mode
    this.modeTarget.value = mode

    const active   = "bg-blue-600 text-white border-blue-600"
    const inactive = "bg-white text-gray-600 border-gray-300 hover:bg-gray-50"
    const andBtn = this.element.querySelector("[data-profile-search-mode-param='and']")
    const orBtn  = this.element.querySelector("[data-profile-search-mode-param='or']")

    andBtn.className = `px-3 py-1.5 rounded-l-lg border text-sm font-medium ${mode === "and" ? active : inactive}`
    orBtn.className  = `px-3 py-1.5 rounded-r-lg border-t border-b border-r text-sm font-medium ${mode === "or" ? active : inactive}`

    this.formTarget.requestSubmit()
  }
}
