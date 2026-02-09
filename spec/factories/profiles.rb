FactoryBot.define do
  factory :profile do
    association :user
    sequence(:nickname) { |n| "test#{n}" }
  end
end

# profile = create(:profile)
