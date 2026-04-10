class Admin::UnclassifiedHobbiesController < Admin::BaseController
  def index
    scope = Hobby.unclassified
                 .left_joins(:profile_hobbies)
                 .select("hobbies.*, COUNT(DISTINCT profile_hobbies.id) AS usage_count, COUNT(DISTINCT profile_hobbies.profile_id) AS user_count")
                 .group("hobbies.id")
    scope = scope.where("hobbies.name LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @hobbies = scope
    @parent_tags = ParentTag.order(:room_type, :position)
    @all_hobbies = Hobby.order(:name).pluck(:name, :id)
  end

  def update
    @hobby = Hobby.unclassified.find(params[:id])
    if @hobby.update(parent_tag_id: params[:parent_tag_id])
      redirect_to admin_unclassified_hobbies_path, notice: "分類しました"
    else
      redirect_to admin_unclassified_hobbies_path, alert: "分類に失敗しました"
    end
  end

  def merge
    source = Hobby.unclassified.find(params[:id])
    target = Hobby.find(params[:target_hobby_id])
    result = Admin::HobbyMergeService.call(source:, target:)
    if result.success?
      redirect_to admin_unclassified_hobbies_path, notice: "統合しました"
    else
      redirect_to admin_unclassified_hobbies_path, alert: result.error
    end
  end
end
