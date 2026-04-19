import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  // モーダルを開き、背景スクロールを無効化する
  open() {
    this.panelTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  // モーダルを閉じ、背景スクロールを復元する
  close() {
    this.panelTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
}
