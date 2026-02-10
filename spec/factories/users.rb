FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password123" }
    nickname { "test_user" }
  end
end

# user = create(:user) 呼び出す
