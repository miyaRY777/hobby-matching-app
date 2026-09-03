class MypageRoomsQuery
  PER = 10

  def self.call(profile:, page:)
    new(profile, page).call
  end

  def initialize(profile, page)
    @profile = profile
    @page = page
  end

  def call
    combined = (issued + joined).sort_by { |item|
      item.is_a?(Room) ? item.created_at : item.room.created_at
    }.reverse

    Kaminari.paginate_array(combined).page(@page).per(PER)
  end

  private

  def issued
    @profile.issued_rooms
            .includes(:share_link, :room_memberships)
            .order(created_at: :desc)
            .to_a
  end

  def joined
    @profile.room_memberships
            .joins(:room)
            .where.not(rooms: { issuer_profile_id: @profile.id })
            .includes(room: [ { issuer_profile: :user }, :room_memberships, :share_link ])
            .order("rooms.created_at DESC")
            .to_a
  end
end
