import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tag", "description", "panel"]
  static values = { bio: String }

  // 接続時に、bioをpanelへ表示して非表示状態を解除する
  connect() {
    if (this.hasPanelTarget) {
      this.panelTarget.textContent = this.bioValue
      this.panelTarget.classList.remove("hidden")
    }
  }

  toggle(event) {
    const clickedTag = event.currentTarget
    const wasActive = clickedTag.dataset.active === "true"

    // 一旦、全タグを非アクティブに戻す
    this.tagTargets.forEach(tag => {
      tag.dataset.active = "false"
      tag.classList.remove("bg-blue-600", "text-white")
      tag.classList.add("bg-blue-100", "text-blue-800")
    })

    // 同じタグを再クリックしたかで分岐する
    if (wasActive) {
      
      // 同じタグ再クリック → bioに戻る
      this.panelTarget.textContent = this.bioValue
    } else {
      this.#openTag(clickedTag)
    }
  }

  // private

  // 選ばれたタグをアクティブにして、その説明文を panel に表示する処理
  #openTag(tagEl) {
    const name = tagEl.dataset.name
    tagEl.dataset.active = "true"
    tagEl.classList.remove("bg-blue-100", "text-blue-800")
    tagEl.classList.add("bg-blue-600", "text-white")

    const desc = this.descriptionTargets.find(el => el.dataset.name === name)
    this.panelTarget.textContent = desc ? desc.textContent.trim() : ""
    this.panelTarget.classList.remove("hidden")
  }
}
