FactoryBot.define do
  factory :hobby do
    sequence(:name) { |n| "hobby#{n}" }
  end
end

# hobby = create(:hobby)