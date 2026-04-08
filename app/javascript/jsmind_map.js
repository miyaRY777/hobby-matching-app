import jsMind from "jsmind";

// メンバー詳細フレームのタブ初期化
function initMemberDetailTabs(frame) {
  const tabs = Array.from(frame.querySelectorAll("[data-tab-index]"))
  const panels = Array.from(frame.querySelectorAll("[data-panel-index]"))
  if (tabs.length === 0) return

  function activate(index) {
    tabs.forEach((tab, i) => {
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
    panels.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }

  tabs.forEach((tab, i) => {
    tab.addEventListener("click", () => activate(i))
  })

  activate(0)
}

document.addEventListener("turbo:frame-load", (event) => {
  if (event.target.id === "member_detail") {
    initMemberDetailTabs(event.target)
  }
})

document.addEventListener("turbo:load", () => {
  const container = document.getElementById("jsmind_container");
  if (!container) return;

  const mindData = JSON.parse(container.dataset.jsmind);

  const options = {
    container: "jsmind_container",
    theme: "primary",
    editable: false,
    mode: "full",
  };

  const jm = new jsMind(options);
  jm.show(mindData);

  jm.add_event_listener((type, data) => {
    if (type !== jsMind.event_type.select) return;

    const nodeId = data.node;
    const node = jm.get_node(nodeId);

    const url = node?.data?.data?.url;
    if (!url) return;

    document.getElementById("member_detail").src = url;
  });
});
