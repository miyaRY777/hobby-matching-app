module RoomsHelper
  ROOM_TYPE_BADGES = {
    "chat"  => { label: "雑談",   color: "rgba(37, 99, 235, 0.2)",  border: "rgba(96, 165, 250, 0.4)",  text: "#93c5fd" },
    "study" => { label: "勉強",   color: "rgba(22, 163, 74, 0.2)",  border: "rgba(74, 222, 128, 0.4)",  text: "#86efac" },
    "game"  => { label: "ゲーム", color: "rgba(124, 58, 237, 0.2)", border: "rgba(167, 139, 250, 0.4)", text: "#c4b5fd" }
  }.freeze

  LOCK_STATUS_BADGES = {
    true  => { label: "ロック中", color: "rgba(239, 68, 68, 0.15)",  border: "rgba(239, 68, 68, 0.3)",  text: "#fca5a5" },
    false => { label: "公開中",   color: "rgba(34, 197, 94, 0.15)",  border: "rgba(34, 197, 94, 0.3)",  text: "#86efac" }
  }.freeze

  def room_type_badge(room_type)
    ROOM_TYPE_BADGES[room_type]
  end

  def lock_status_badge(room)
    LOCK_STATUS_BADGES[room.locked?]
  end
end
