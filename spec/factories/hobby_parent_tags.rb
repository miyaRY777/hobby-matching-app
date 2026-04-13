FactoryBot.define do
  factory :hobby_parent_tag do
    association :hobby
    association :parent_tag, room_type: :chat
  end
end
