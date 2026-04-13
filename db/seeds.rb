# 親タグの初期データ
parent_tags = [
  # 雑談系（chat）
  { name: "アニメ", slug: "anime", room_type: :chat, position: 0 },
  { name: "ゲーム", slug: "game", room_type: :chat, position: 1 },
  { name: "音楽", slug: "music", room_type: :chat, position: 2 },
  { name: "カフェ", slug: "cafe", room_type: :chat, position: 3 },
  { name: "未分類", slug: "uncategorized", room_type: :chat, position: 999 },
  # 勉強系（study）
  { name: "プログラミング", slug: "programming", room_type: :study, position: 0 },
  { name: "デザイン", slug: "design", room_type: :study, position: 1 },
  { name: "学習スタイル", slug: "learning-style", room_type: :study, position: 2 },
  { name: "未分類", slug: "uncategorized", room_type: :study, position: 999 },
  # ゲーム系（game）
  { name: "協力ゲーム", slug: "coop", room_type: :game, position: 0 },
  { name: "対戦ゲーム", slug: "versus", room_type: :game, position: 1 },
  { name: "カジュアル", slug: "casual", room_type: :game, position: 2 },
  { name: "未分類", slug: "uncategorized", room_type: :game, position: 999 }
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

# 子タグ辞書: normalized_name => parent_tag slug
HOBBY_DICTIONARY = {
  "rails" => "programming", "ruby" => "programming",
  "javascript" => "programming", "sql" => "programming",
  "git" => "programming", "react" => "programming", "rubocop" => "programming",
  "figma" => "design", "ui/ux" => "design",
  "もくもく会" => "learning-style", "個人開発" => "learning-style", "アウトプット" => "learning-style",
  "アニメ" => "anime", "呪術廻戦" => "anime", "ワンピース" => "anime",
  "ガンダム" => "anime", "鬼滅の刃" => "anime", "漫画" => "anime",
  "マイクラ" => "game", "lol" => "game", "apex" => "game", "テラリア" => "game",
  "among us" => "coop", "モンハン" => "coop",
  "fps" => "versus",
  "エンジョイ勢" => "casual", "初心者歓迎" => "casual",
  "音楽鑑賞" => "music", "アニソン" => "music",
  "カフェ巡り" => "cafe", "コーヒー" => "cafe", "スタバ" => "cafe"
}.freeze

# 既存 hobbies を hobby_parent_tags で分類（冪等: 既に分類済みの room_type は skip）
parent_tag_by_slug = ParentTag.all.group_by(&:slug)
classified_count = 0

Hobby.find_each do |hobby|
  slug = HOBBY_DICTIONARY[hobby.normalized_name]
  next unless slug

  parent_tag_by_slug[slug]&.each do |parent_tag|
    next if hobby.hobby_parent_tags.exists?(room_type: parent_tag.room_type)

    Admin::HobbyClassificationService.call(hobby:, parent_tag:)
    classified_count += 1
  end
end

puts "Hobbies classified: #{classified_count} 件"
