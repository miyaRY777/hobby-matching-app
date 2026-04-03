FactoryBot.define do
  factory :parent_tag do
    sequence(:name) { |n| "親タグ#{n}" }
    sequence(:slug) { |n| "parent-tag-#{n}" }
    room_type { nil }
    position { 0 }
  end
end
