module RoomsHelper
  ROOM_TYPE_BADGES = {
    "chat"  => { label: "雑談",   color: "rgba(37, 99, 235, 0.2)",  border: "rgba(96, 165, 250, 0.4)",  text: "#93c5fd" },
    "study" => { label: "勉強",   color: "rgba(22, 163, 74, 0.2)",  border: "rgba(74, 222, 128, 0.4)",  text: "#86efac" },
    "game"  => { label: "ゲーム", color: "rgba(124, 58, 237, 0.2)", border: "rgba(167, 139, 250, 0.4)", text: "#c4b5fd" }
  }.freeze

  LOCK_STATUS_BADGES = {
    true  => { label: "非公開",   color: "rgba(239, 68, 68, 0.15)",  border: "rgba(239, 68, 68, 0.3)",  text: "#fca5a5" },
    false => { label: "公開中",   color: "rgba(34, 197, 94, 0.15)",  border: "rgba(34, 197, 94, 0.3)",  text: "#86efac" }
  }.freeze

  MEMBERSHIP_STATUS_BADGES = {
    owner:    { label: "Owner",    color: "rgba(124, 58, 237, 0.2)",  border: "rgba(167, 139, 250, 0.4)", text: "#c4b5fd" },
    joined:   { label: "参加済み", color: "rgba(34, 197, 94, 0.15)",  border: "rgba(34, 197, 94, 0.3)",  text: "#86efac" },
    unjoined: { label: "未参加",   color: "rgba(255,255,255,0.05)", border: "rgba(107, 114, 128, 0.35)", text: "#cbd5e1" }
  }.freeze

  MANAGEMENT_ACTION_BADGES = {
    edit:       { color: "rgba(255,255,255,0.04)", border: "rgba(55, 65, 81, 0.5)",  text: "#d1d5db" },
    leave:      { color: "rgba(239, 68, 68, 0.15)",  border: "rgba(239, 68, 68, 0.3)",  text: "#fca5a5" },
    copy:       { color: "rgba(96, 165, 250, 0.1)", border: "rgba(96, 165, 250, 0.3)", text: "#60a5fa" },
    regenerate: { color: "rgba(251, 191, 36, 0.1)", border: "rgba(251, 191, 36, 0.3)", text: "#fbbf24" }
  }.freeze

  def room_type_badge(room_type)
    ROOM_TYPE_BADGES[room_type]
  end

  def lock_status_badge(room)
    LOCK_STATUS_BADGES[room.locked?]
  end

  def membership_status_badge(issued:, joined:)
    if issued
      MEMBERSHIP_STATUS_BADGES[:owner]
    elsif joined
      MEMBERSHIP_STATUS_BADGES[:joined]
    else
      MEMBERSHIP_STATUS_BADGES[:unjoined]
    end
  end

  # 公開部屋一覧・部屋管理の操作ボタン共通スタイル
  def room_action_badge_style(action, issued: false)
    badge = room_action_badge_colors(action, issued:)
    room_table_action_button_style(badge)
  end

  def room_management_button_style(action, issued: true)
    room_action_badge_style(action, issued:)
  end

  def room_table_menu_button_style
    "display: inline-flex; align-items: center; justify-content: center; width: 2.125rem; height: 2.125rem; padding: 0; border-radius: 0.375rem; font-size: 0.8125rem; font-weight: 500; background: rgba(255,255,255,0.04); border: 1px solid rgba(55, 65, 81, 0.5); color: #d1d5db; cursor: pointer; box-sizing: border-box; flex-shrink: 0;"
  end

  def room_table_action_button_style(badge)
    "display: inline-flex; align-items: center; justify-content: center; min-width: 5.5rem; padding: 0.375rem 0.75rem; border-radius: 0.375rem; font-size: 0.8125rem; font-weight: 500; background: #{badge[:color]}; border: 1px solid #{badge[:border]}; color: #{badge[:text]}; text-decoration: none; cursor: pointer; box-sizing: border-box;"
  end

  def room_badge_pill_style(badge)
    "display: inline-flex; align-items: center; padding: 0.125rem 0.625rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 500; background: #{badge[:color]}; border: 1px solid #{badge[:border]}; color: #{badge[:text]};"
  end

  private

  def room_action_badge_colors(action, issued:)
    case action
    when :enter
      MEMBERSHIP_STATUS_BADGES[:joined]
    when :peek
      MEMBERSHIP_STATUS_BADGES[:unjoined]
    when :join
      ROOM_TYPE_BADGES["chat"]
    when :edit
      MANAGEMENT_ACTION_BADGES[:edit]
    when :leave
      MANAGEMENT_ACTION_BADGES[:leave]
    when :copy
      MANAGEMENT_ACTION_BADGES[:copy]
    when :regenerate
      MANAGEMENT_ACTION_BADGES[:regenerate]
    end
  end
end
