class Admin::UnclassifiedHobbiesController < Admin::BaseController
  def index
    scope = Hobby.unclassified
                 .left_joins(:profile_hobbies)
                 .select("hobbies.*, COUNT(DISTINCT profile_hobbies.id) AS usage_count, COUNT(DISTINCT profile_hobbies.profile_id) AS user_count")
                 .group("hobbies.id")
    scope = scope.where("hobbies.name LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @hobbies = scope
    @parent_tags = ParentTag.order(:room_type, :position)
    @all_hobbies_grouped = build_all_hobbies_grouped
  end

  def update
    @hobby = Hobby.unclassified.find(params[:id])
    parent_tag = ParentTag.find(params[:parent_tag_id])
    Admin::HobbyClassificationService.call(hobby: @hobby, parent_tag:)
    redirect_to admin_unclassified_hobbies_path, notice: "分類しました"
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_unclassified_hobbies_path, alert: "分類に失敗しました"
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

  private

  def build_all_hobbies_grouped
    grouped_hobbies = Hobby.includes(:hobby_parent_tags)
                           .order(:name)
                           .each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |hobby, hash|
      room_type = hobby.hobby_parent_tags.min_by(&:room_type_before_type_cast)&.room_type || "unclassified"
      hash[room_type] << [ hobby.name, hobby.id ]
    end

    ParentTag.room_types.keys
             .append("unclassified")
             .index_with { |room_type| grouped_hobbies[room_type] }
             .reject { |_, hobbies| hobbies.empty? }
  end
end
