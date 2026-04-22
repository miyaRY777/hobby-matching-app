import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    defaultOpen: { type: Boolean, default: true },
    toggleable: { type: Boolean, default: true }
  }

  connect() {
    this.activeIndex = null

    if (this.defaultOpenValue && this.tabTargets.length > 0) {
      this.activate(0)
    } else {
      this.deactivate()
    }
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)

    if (index === -1) return

    if (this.activeIndex === index) {
      if (this.toggleableValue) this.deactivate()
      return
    }

    this.activate(index)
  }

  activate(index) {
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        this.applyTabStyle(tab, true)
      } else {
        this.applyTabStyle(tab, false)
      }
    })

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })

    this.activeIndex = index
  }

  deactivate() {
    this.tabTargets.forEach((tab) => this.applyTabStyle(tab, false))
    this.panelTargets.forEach((panel) => panel.classList.add("hidden"))
    this.activeIndex = null
  }

  applyTabStyle(tab, isActive) {
    const variant = tab.dataset.tabsVariant || "default"
    const styles = this.tabStylesFor(variant, isActive)

    tab.style.background = styles.background
    tab.style.color = styles.color
    tab.style.borderColor = styles.borderColor
  }

  tabStylesFor(variant, isActive) {
    if (variant === "bio") {
      return isActive
        ? {
            background: "linear-gradient(135deg, #d97706, #b45309)",
            color: "#ffffff",
            borderColor: "transparent"
          }
        : {
            background: "rgba(251, 191, 36, 0.12)",
            color: "#fbbf24",
            borderColor: "#fbbf24"
          }
    }

    return isActive
      ? {
          background: "linear-gradient(135deg, #2563eb, #1d4ed8)",
          color: "#ffffff",
          borderColor: "transparent"
        }
      : {
          background: "rgba(96, 165, 250, 0.15)",
          color: "#60a5fa",
          borderColor: "rgba(96, 165, 250, 0.4)"
        }
  }
}
