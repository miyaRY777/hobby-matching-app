import jsMind from "jsmind";

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
    const node = jm.get_node(data.node);
    const url = node && node.data && node.data.data && node.data.data.url;
    if (!url) return;

    document.getElementById("member_detail").src = url;
  });
});
