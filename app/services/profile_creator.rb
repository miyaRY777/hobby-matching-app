class ProfileCreator
  def self.call(user:, profile_params:)
    new(user, profile_params).call
  end

  def initialize(user, profile_params)
    @user = user
    @profile_params = profile_params
  end

  def call
    # hobbies_json はカラムではなく attr_accessor。build には渡さず個別に代入する
    profile = @user.build_profile(@profile_params.except(:hobbies_json))
    profile.hobbies_json = @profile_params[:hobbies_json]

    # 保存と趣味同期を1トランザクションで束ねる。同期失敗時は Profile も残さない
    ApplicationRecord.transaction do
      profile.save!
      profile.update_hobbies_from_json(profile.hobbies_json)
    end

    # 返り値の形を RoomCreator と揃える。Controller は success を見て redirect / render する
    { success: true, profile: profile }
  rescue ActiveRecord::RecordInvalid
    { success: false, profile: profile }
  end
end
