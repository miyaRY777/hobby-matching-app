class ProfileUpdater
  def self.call(profile:, profile_params:)
    new(profile, profile_params).call
  end

  def initialize(profile, profile_params)
    @profile = profile
    @profile_params = profile_params
  end

  def call
    # hobbies_json はカラムではなく attr_accessor。update! には渡さず個別に代入する
    @profile.hobbies_json = @profile_params[:hobbies_json]

    # 更新と趣味同期を1トランザクションで束ねる。同期失敗時は Profile の更新も戻す
    ApplicationRecord.transaction do
      @profile.update!(@profile_params.except(:hobbies_json))
      # hobbies_json が空なら bio のみ更新。既存趣味は触らない
      @profile.update_hobbies_from_json(@profile.hobbies_json) if @profile.hobbies_json.present?
    end

    # 返り値の形を RoomCreator と揃える。Controller は success を見て redirect / render する
    { success: true, profile: @profile }
  rescue ActiveRecord::RecordInvalid
    { success: false, profile: @profile }
  end
end
