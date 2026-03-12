class ProfileHobbiesUpdater
  # tag_data: [{ name: String, description: String }, ...]
  def self.call(profile, tag_data)
    normalized = tag_data
      .map { |t| { name: t[:name].to_s.strip.downcase, description: t[:description].to_s } }
      .reject { |t| t[:name].blank? }
      .uniq { |t| t[:name] }

    ApplicationRecord.transaction do
      target_names = normalized.map { |t| t[:name] }

      # 不要なprofile_hobbiesを削除
      profile.profile_hobbies
             .joins(:hobby)
             .where.not(hobbies: { name: target_names })
             .destroy_all

      # 既存の更新 + 新規作成
      normalized.each do |tag|
        hobby = Hobby.find_or_create_by!(name: tag[:name])
        ph = profile.profile_hobbies.find_or_initialize_by(hobby:)
        ph.description = tag[:description]
        ph.save!
      end
    end
  end
end
