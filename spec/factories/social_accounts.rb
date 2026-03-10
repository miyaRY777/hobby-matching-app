FactoryBot.define do
  factory :social_account do
    association :user
    provider { "google_oauth2" }
    sequence(:uid) { |n| "google_uid_#{n}" }
  end
end
