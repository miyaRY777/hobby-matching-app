module ApplicationHelper
  def primary_btn_class(size: :lg)
    base = "inline-flex items-center justify-center rounded-lg font-semibold"
    padding = size == :lg ? "px-8 py-3 text-lg" : "px-4 py-2 text-sm"
    "#{base} #{padding} bg-blue-600 text-white hover:bg-blue-700"
  end

  def outline_btn_class(size: :lg)
    base = "inline-flex items-center justify-center rounded-lg font-semibold"
    padding = size == :lg ? "px-8 py-3 text-lg" : "px-4 py-2 text-sm"
    "#{base} #{padding} border border-gray-600 text-gray-300 hover:bg-gray-800 hover:text-white"
  end

  def recent_room_nav_path(user)
    token = cookies[:recent_room_token]
    return share_path(token) if token.present?

    profile = user&.profile
    return nil unless profile

    room = profile.last_joined_room_with_share_link
    return nil unless room

    room.shareable? ? share_path(room.share_link.token) : mypage_rooms_path
  end

  def avatar_image_tag(user, size: :medium)
    sizes = { small: 32, medium: 64 }
    px = sizes[size]
    style = "width: #{px}px; height: #{px}px; border-radius: 50%; object-fit: cover; border: 1px solid rgba(255,255,255,0.15); box-shadow: 0 2px 8px rgba(0,0,0,0.4);"

    if user.avatar.attached?
      image_tag user.avatar, style: style, data: { testid: "avatar" }
    else
      tag.img(
        src: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='1.5'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' d='M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z'/%3E%3C/svg%3E",
        style: "#{style} background: rgba(255,255,255,0.1); padding: #{px / 5}px;",
        data: { testid: "avatar" }
      )
    end
  end
end
