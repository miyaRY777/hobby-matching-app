class Profile < ApplicationRecord
  belongs_to :user
  validates :user_id, uniqueness: true
  validates :bio, presence: true, length: { maximum: 500 }

  has_many :profile_hobbies, dependent: :destroy
  has_many :hobbies, through: :profile_hobbies

  def update_hobbies_from(str)
    names = HobbyNamesParser.call(str)

    hobbies = names.map do |name|
      Hobby.find_or_create_by!(name: name)
    end

    self.hobbies = hobbies
  end
end
