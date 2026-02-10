FactoryBot.define do
  factory :profile_hobby do
    association :profile
    association :hobby
  end
end

# create(:profile_hobby)

# Profile が1件 自動生成
# Hobby が1件 自動生成
# その2つを紐づけた ProfileHobby が生成
