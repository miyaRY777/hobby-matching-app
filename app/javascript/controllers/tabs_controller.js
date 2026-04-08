import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.activate(0)
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.activate(index)
  }

  activate(index) {
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.style.background = "linear-gradient(135deg, #2563eb, #1d4ed8)"
        tab.style.color = "#ffffff"
        tab.style.borderColor = "transparent"
      } else {
        tab.style.background = "rgba(96, 165, 250, 0.15)"
        tab.style.color = "#60a5fa"
        tab.style.borderColor = "rgba(96, 165, 250, 0.4)"
      }
    })
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
