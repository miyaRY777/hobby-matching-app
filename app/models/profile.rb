class Profile < ApplicationRecord
  belongs_to :user
  validates :user_id, uniqueness: true
  validates :bio, presence: true, length: { maximum: 500 }

  has_many :profile_hobbies, dependent: :destroy
  has_many :hobbies, through: :profile_hobbies
  has_many :room_memberships, dependent: :destroy
  has_many :joined_rooms, through: :room_memberships, source: :room
  has_many :issued_rooms, class_name: "Room", foreign_key: :issuer_profile_id, inverse_of: :issuer_profile, dependent: :destroy

  attr_accessor :hobbies_text

  MAX_HOBBIES = 10

  validate :hobbies_text_count_within_limit, if: -> { hobbies_text.present? }

  def update_hobbies_from(str)
    names = HobbyNamesParser.call(str)

    hobbies = names.map do |name|
      Hobby.find_or_create_by!(name: name)
    end

    self.hobbies = hobbies
  end

  def shared_hobbies_with(other_profile)
    hobbies.to_a & other_profile.hobbies.to_a
  end

  private

  def hobbies_text_count_within_limit
    names = HobbyNamesParser.call(hobbies_text)
    return if names.size <= MAX_HOBBIES

    errors.add(:hobbies_text, "は#{MAX_HOBBIES}個以下にしてください")
  end
end
