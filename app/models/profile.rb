class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :bio, presence: true, length: { maximum: 500 }

  has_many :profile_hobbies, dependent: :destroy
  has_many :hobbies, through: :profile_hobbies
  has_many :room_memberships, dependent: :destroy
  has_many :joined_rooms, through: :room_memberships, source: :room
  has_many :issued_rooms, class_name: "Room", foreign_key: :issuer_profile_id, inverse_of: :issuer_profile, dependent: :destroy

  # タグ入力フォームから送られる趣味JSON。DBカラムではない
  attr_accessor :hobbies_json

  MAX_HOBBIES = 10

  validate :hobbies_json_not_empty
  validate :hobbies_json_count_within_limit, if: -> { hobbies_json.present? }

  def update_hobbies_from_json(json_str)
    tag_data = JSON.parse(json_str).map(&:symbolize_keys)
    ProfileHobbiesUpdater.call(self, tag_data)
  rescue JSON::ParserError
    # パース失敗時は何もしない
  end

  def joined_room_ids
    room_memberships.pluck(:room_id)
  end

  def issued_room_ids
    issued_rooms.pluck(:id)
  end

  def last_joined_room_with_share_link
    room_memberships.eager_load(room: :share_link)
                    .order(created_at: :desc)
                    .first
                    &.room
  end

  def shared_hobbies_with(other_profile)
    hobbies.to_a & other_profile.hobbies.to_a
  end

  private

  # 新規作成時は必須。更新時は hobbies_json が送られたときだけ検証する（bio のみ更新を許可するため）
  def hobbies_json_not_empty
    if new_record?
      validate_hobbies_json_presence(hobbies_json)
      return
    end

    validate_hobbies_json_presence(hobbies_json) if hobbies_json.present?
  end

  def validate_hobbies_json_presence(raw_value)
    if raw_value.blank?
      errors.add(:hobbies_json, "を1つ以上追加してください")
      return
    end

    tags = JSON.parse(raw_value)
    errors.add(:hobbies_json, "を1つ以上追加してください") if tags.empty?
  rescue JSON::ParserError
    errors.add(:hobbies_json, "を1つ以上追加してください")
  end

  def hobbies_json_count_within_limit
    tags = JSON.parse(hobbies_json)
    return if tags.size <= MAX_HOBBIES

    errors.add(:hobbies_json, "は#{MAX_HOBBIES}個以下にしてください")
  rescue JSON::ParserError
    # 不正JSONのエラーは hobbies_json_not_empty 側で扱う
    nil
  end
end
