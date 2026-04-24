class Admin::ParentTagsController < Admin::BaseController
  before_action :set_parent_tag, only: %i[edit update destroy]
  before_action :set_parent_tag_options, only: %i[index new create edit update]

  def index
    base_scope = ParentTag.classified.includes(:hobbies).order(:position, :id)
    base_scope = base_scope.where(room_type: params[:room_type]) if params[:room_type].present?
    base_scope = base_scope.where(id: params[:parent_tag_id]) if params[:parent_tag_id].present?

    @room_type_options = ParentTag.room_types.keys
    @parent_tags_by_room_type = @room_type_options.each_with_object({}) do |rt, hash|
      hash[rt] = base_scope.where(room_type: rt).page(params[:"#{rt}_page"]).per(10)
    end

    hobby_ids = @parent_tags_by_room_type.values.flat_map { |tags| tags.flat_map { |t| t.hobbies.map(&:id) } }
    @usage_counts = ProfileHobby.where(hobby_id: hobby_ids).group(:hobby_id).count
  end

  def new
    @parent_tag = ParentTag.new(room_type: params[:room_type])
  end

  def create
    @parent_tag = ParentTag.new(parent_tag_params)
    if @parent_tag.save
      redirect_to admin_parent_tags_path, notice: "親タグを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @parent_tag.update(parent_tag_params)
      redirect_to admin_parent_tags_path, notice: "親タグを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @parent_tag.destroy
      redirect_to admin_parent_tags_path, notice: "削除しました"
    else
      child_count = @parent_tag.hobbies.size
      redirect_to admin_parent_tags_path, alert: "子タグが#{child_count}件あるため削除できません"
    end
  end

  private

  def set_parent_tag
    @parent_tag = ParentTag.find(params[:id])
  end

  def set_parent_tag_options
    @all_parent_tags = ParentTag.where.not(room_type: nil).order(:room_type, :position, :id)
  end

  def parent_tag_params
    params.require(:parent_tag).permit(:name, :slug, :room_type)
  end
end
