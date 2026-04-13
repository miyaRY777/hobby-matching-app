class Admin::HobbiesController < Admin::BaseController
  before_action :set_hobby, only: %i[edit update destroy]
  before_action :set_parent_tags, only: %i[new create edit update]

  def new
    @hobby = Hobby.new(parent_tag_id: params[:parent_tag_id])
  end

  def create
    @hobby = Hobby.new(hobby_params)
    if @hobby.save
      redirect_to admin_parent_tags_path, notice: "子タグを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @hobby.update(hobby_params)
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
    @parent_tags = ParentTag.classified.order(:room_type, :position, :id)
  end

  def hobby_params
    params.require(:hobby).permit(:name, :parent_tag_id)
  end
end
