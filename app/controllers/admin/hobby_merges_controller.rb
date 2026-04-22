class Admin::HobbyMergesController < Admin::BaseController
  def new
    @grouped_hobby_options = build_grouped_hobby_options
  end

  def create
    source = Hobby.find(params[:source_hobby_id])
    target = Hobby.find(params[:target_hobby_id])
    result = Admin::HobbyMergeService.call(source:, target:)

    if result.success?
      redirect_to new_admin_hobby_merge_path,
                  notice: "「#{source.name}」を「#{target.name}」に統合しました"
    else
      @grouped_hobby_options = build_grouped_hobby_options
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def build_grouped_hobby_options
    hobbies = Hobby.includes(hobby_parent_tags: :parent_tag).order(:name)
    grouped = hobbies.group_by { |hobby| hobby.primary_parent_tag_info[:parent_tag_name] || "未分類" }

    ordered_labels = grouped.keys.reject { |label| label == "未分類" }.sort
    ordered_labels << "未分類" if grouped.key?("未分類")

    ordered_labels.map do |label|
      options = grouped[label].sort_by(&:name).map { |hobby| [ hobby.name, hobby.id ] }
      [ label, options ]
    end
  end
end
