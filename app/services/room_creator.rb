class RoomCreator
  def self.call(issuer_profile:, room_params:, expires_in:)
    new(issuer_profile, room_params, expires_in).call
  end

  def initialize(issuer_profile, room_params, expires_in)
    @issuer_profile = issuer_profile
    @room_params = room_params
    @expires_in = expires_in
  end

  def call
    room = Room.new(@room_params.merge(issuer_profile: @issuer_profile))
    return failure(room) unless room.valid?
    expires_in_value = normalize_expires_in(@expires_in)
    expires_at = ShareLink::EXPIRES_IN_MAP[expires_in_value]&.from_now
    ApplicationRecord.transaction do
      room.save!
      RoomMembership.create!(room: room, profile: @issuer_profile)
      ShareLink.create!(room: room, expires_at: expires_at, expires_in: expires_in_value)
    end
    { success: true, room: room }
  end

  private

  def normalize_expires_in(raw)
    ShareLink::EXPIRES_IN_MAP.key?(raw) ? raw : nil
  end

  def failure(room)
    { success: false, room: room }
  end
end
