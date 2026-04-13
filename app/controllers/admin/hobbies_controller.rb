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
      Admin::HobbyClassificationService.call_bulk(hobby: @hobby, room_type_to_parent_tag_id: bulk_parent_tag_params)
      redirect_to admin_parent_tags_path, notice: "子タグを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @hobby.update(name: hobby_params[:name])
      Admin::HobbyClassificationService.call_bulk(hobby: @hobby, room_type_to_parent_tag_id: bulk_parent_tag_params)
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

  def bulk_parent_tag_params
    ParentTag.room_types.keys.to_h do |room_type|
      [ room_type, hobby_params[:"#{room_type}_parent_tag_id"] ]
    end
  end
end
