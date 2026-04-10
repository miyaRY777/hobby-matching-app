class Hobby < ApplicationRecord
  belongs_to :parent_tag, optional: true

  scope :unclassified, -> { where(parent_tag: ParentTag.where(slug: "uncategorized")) }

  has_many :profile_hobbies, dependent: :destroy
  has_many :profiles, through: :profile_hobbies

  validates :name, presence: true, uniqueness: true

  before_save :set_normalized_name

  def self.normalize(name)
    name.to_s.unicode_normalize(:nfkc).strip.downcase
  end

  private

  def set_normalized_name
    self.normalized_name = self.class.normalize(name)
  end
end
