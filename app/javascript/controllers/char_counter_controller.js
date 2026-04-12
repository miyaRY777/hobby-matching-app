import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display"]
  static values = { max: { type: Number, default: 500 } }

  connect() {
    this.#update()
    this.#resize()
  }

  count() {
    this.#update()
    this.#resize()
  }

  // private

  #update() {
    const len = this.inputTarget.value.length
    this.displayTarget.textContent = `${len} / ${this.maxValue}字`
  }

  #resize() {
    const el = this.inputTarget
    el.style.height = "auto"
    el.style.height = `${el.scrollHeight}px`
  }
}
