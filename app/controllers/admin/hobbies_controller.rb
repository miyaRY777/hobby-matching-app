class Admin::HobbiesController < Admin::BaseController
  before_action :set_hobby, only: %i[edit update destroy]
  before_action :set_parent_tags, only: %i[new create edit update]

  def new
    @hobby = Hobby.new
    @initial_parent_tag = ParentTag.find_by(id: params[:parent_tag_id])
  end

  def create
    @hobby = Hobby.new(name: hobby_params[:name])
    if @hobby.save
      classify_hobby(@hobby)
      redirect_to admin_parent_tags_path, notice: "子タグを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @hobby.update(name: hobby_params[:name])
      classify_hobby(@hobby)
      redirect_to admin_parent_tags_path, notice: "子タグを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @hobby.destroy
      redirect_to admin_parent_tags_path, notice: "削除しました"
    else
      usage_count = @hobby.profile_hobbies.size
      redirect_to admin_parent_tags_path, alert: "使用中のため削除できません（#{usage_count}件が使用中）"
    end
  end

  private

  def set_hobby
    @hobby = Hobby.find(params[:id])
  end

  def set_parent_tags
    @parent_tags_by_room_type = ParentTag.order(:room_type, :position).group_by(&:room_type)
  end

  def hobby_params
    params.require(:hobby).permit(
      :name,
      :chat_parent_tag_id,
      :study_parent_tag_id,
      :game_parent_tag_id
    )
  end

  def classify_hobby(hobby)
    ParentTag.room_types.each_key do |room_type|
      parent_tag_id = hobby_params[:"#{room_type}_parent_tag_id"]
      next if parent_tag_id.blank?

      parent_tag = ParentTag.find(parent_tag_id)
      Admin::HobbyClassificationService.call(hobby:, parent_tag:)
    end
  end
end
