# 親タグの初期データ
parent_tags = [
  # 雑談系（chat）
  { name: "アニメ", slug: "anime", room_type: :chat, position: 0 },
  { name: "ゲーム", slug: "game", room_type: :chat, position: 1 },
  { name: "音楽", slug: "music", room_type: :chat, position: 2 },
  { name: "カフェ", slug: "cafe", room_type: :chat, position: 3 },
  # 勉強系（study）
  { name: "プログラミング", slug: "programming", room_type: :study, position: 0 },
  { name: "デザイン", slug: "design", room_type: :study, position: 1 },
  { name: "学習スタイル", slug: "learning-style", room_type: :study, position: 2 },
  # ゲーム系（game）
  { name: "協力ゲーム", slug: "coop", room_type: :game, position: 0 },
  { name: "対戦ゲーム", slug: "versus", room_type: :game, position: 1 },
  { name: "カジュアル", slug: "casual", room_type: :game, position: 2 },
  # 共通（未分類）
  { name: "未分類", slug: "uncategorized", room_type: nil, position: 0 }
]

parent_tags.each do |attrs|
  ParentTag.find_or_create_by!(slug: attrs[:slug], room_type: attrs[:room_type]) do |pt|
    pt.name = attrs[:name]
    pt.position = attrs[:position]
  end
end

puts "ParentTags: #{ParentTag.count} 件"

# 既存 hobbies の normalized_name を一括設定
Hobby.where(normalized_name: nil).find_each do |hobby|
  hobby.update_columns(normalized_name: Hobby.normalize(hobby.name))
end

puts "Hobbies normalized: #{Hobby.where.not(normalized_name: nil).count} 件"
