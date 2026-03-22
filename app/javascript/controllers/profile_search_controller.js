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

    const andBtn = this.element.querySelector("[data-profile-search-mode-param='and']")
    const orBtn  = this.element.querySelector("[data-profile-search-mode-param='or']")

    const activeStyle = "background: linear-gradient(135deg, #2563eb, #1d4ed8); color: #ffffff; border-color: #2563eb;"
    const inactiveStyle = "background: rgba(255,255,255,0.05); color: #9ca3af; border-color: rgba(55, 65, 81, 0.6);"

    andBtn.style.cssText = `padding: 0.375rem 0.75rem; border-radius: 0.5rem 0 0 0.5rem; border: 1px solid; font-size: 0.875rem; font-weight: 500; cursor: pointer; ${mode === "and" ? activeStyle : inactiveStyle}`
    orBtn.style.cssText  = `padding: 0.375rem 0.75rem; border-radius: 0 0.5rem 0.5rem 0; border: 1px solid; border-left: none; font-size: 0.875rem; font-weight: 500; cursor: pointer; ${mode === "or" ? activeStyle : inactiveStyle}`

    this.formTarget.requestSubmit()
  }
}
