class Admin::UnclassifiedHobbiesController < Admin::BaseController
  def index
    scope = Hobby.unclassified
                 .left_joins(:profile_hobbies)
                 .select("hobbies.*, COUNT(DISTINCT profile_hobbies.id) AS usage_count, COUNT(DISTINCT profile_hobbies.profile_id) AS user_count")
                 .group("hobbies.id")
    scope = scope.where("hobbies.name LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @hobbies = scope
    @parent_tags = ParentTag.order(:room_type, :position)
    @grouped_parent_tag_options = build_grouped_parent_tag_options
  end

  def update
    @hobby = Hobby.unclassified.find(params[:id])
    parent_tag = ParentTag.find(params[:parent_tag_id])
    Admin::HobbyClassificationService.call(hobby: @hobby, parent_tag:)
    redirect_to admin_unclassified_hobbies_path, notice: "分類しました"
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_unclassified_hobbies_path, alert: "分類に失敗しました"
  end

  def destroy
    @hobby = Hobby.unclassified.find(params[:id])
    # UI側でも usage_count == 0 のときのみボタン表示しているが、直接リクエストへの二重防御として rescue を残している
    @hobby.destroy!
    redirect_to admin_unclassified_hobbies_path, notice: "削除しました"
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to admin_unclassified_hobbies_path, alert: "削除できませんでした（使用中のタグは削除できません）"
  end

  private

  def build_grouped_parent_tag_options
    ParentTag.room_types.keys.to_h do |room_type|
      [
        room_type,
        @parent_tags.select { |pt| pt.room_type == room_type }.map { |pt| [ pt.name, pt.id ] }
      ]
    end
  end
end
