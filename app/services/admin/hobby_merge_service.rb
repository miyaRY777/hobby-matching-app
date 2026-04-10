class Admin::HobbyMergeService
  Result = Struct.new(:success?, :error, keyword_init: true)

  def self.call(source:, target:)
    new(source:, target:).call
  end

  def initialize(source:, target:)
    @source = source
    @target = target
  end

  def call
    return Result.new(success?: false, error: "統合元と統合先が同じです") if @source.id == @target.id

    ActiveRecord::Base.transaction do
      duplicate_profile_ids = ProfileHobby.where(hobby_id: @target.id).pluck(:profile_id)
      ProfileHobby.where(hobby_id: @source.id, profile_id: duplicate_profile_ids).delete_all
      ProfileHobby.where(hobby_id: @source.id).update_all(hobby_id: @target.id)
      @source.destroy!
    end
    Result.new(success?: true, error: nil)
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.message)
  end
end
