class ProfileHobbiesUpdater
  # tag_data: [{ name: String, description: String, parent_tag_id: Integer | nil }, ...]
  def self.call(profile, tag_data)
    normalized = tag_data
      .map do |tag|
        {
          name: Hobby.normalize(tag[:name]),
          description: tag[:description].to_s,
          parent_tag_id: tag[:parent_tag_id]
        }
      end
      .reject { |t| t[:name].blank? }
      .uniq { |t| t[:name] }

    ApplicationRecord.transaction do
      target_names = normalized.map { |t| t[:name] }

      # 不要なprofile_hobbiesを削除
      profile.profile_hobbies
             .joins(:hobby)
             .where.not(hobbies: { normalized_name: target_names })
             .destroy_all

      # N+1対策: 既存Hobbyをバッチロード
      existing_hobbies = Hobby.where(normalized_name: target_names).index_by(&:normalized_name)

      # 移行前データで normalized_name が nil の既存 hobby も再利用する
      missing_names = target_names - existing_hobbies.keys
      legacy_hobbies = Hobby.where(normalized_name: nil, name: missing_names).to_a

      legacy_hobbies.each do |hobby|
        existing_hobbies[hobby.name] ||= hobby
      end

      # N+1対策: 既存ProfileHobbyをバッチロード（destroy_all後に取得）
      existing_phs = profile.profile_hobbies
                            .includes(:hobby)
                            .index_by { |ph| ph.hobby.normalized_name || Hobby.normalize(ph.hobby.name) }

      parent_tag_ids = normalized.filter_map { |t| t[:parent_tag_id] }.uniq
      preloaded_parent_tags = ParentTag.where(id: parent_tag_ids).index_by(&:id)

      normalized.each do |tag|
        hobby = existing_hobbies[tag[:name]] ||
                Hobby.find_or_create_by!(normalized_name: tag[:name]) do |h|
                  h.name = tag[:name]
                end
        classify_if_newly_created(hobby, preloaded_parent_tags[tag[:parent_tag_id]])

        ph = existing_phs[tag[:name]] || ProfileHobby.new(profile:, hobby:)
        ph.description = tag[:description]
        ph.save!
      end
    end
  end

  def self.classify_if_newly_created(hobby, parent_tag)
    return unless hobby.previously_new_record?
    return if parent_tag.nil?

    hobby.hobby_parent_tags.create!(parent_tag:)
  end
end
