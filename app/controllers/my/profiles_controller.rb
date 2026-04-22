class My::ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_profile_exists, only: %i[new create]
  before_action :set_profile, only: %i[edit update destroy]
  before_action :set_parent_tags, only: %i[new create edit update]

  def new
    @profile = current_user.build_profile
  end

  def create
    @profile = current_user.build_profile(profile_params.except(:hobbies_text))
    @profile.hobbies_text = profile_params[:hobbies_text]

    ApplicationRecord.transaction do
      @profile.save!
      @profile.update_hobbies_from_json(@profile.hobbies_text)
    end
    redirect_to mypage_root_path, notice: "プロフィールを作成しました"
  rescue ActiveRecord::RecordInvalid
    @hobbies_text = @profile.hobbies_text
    flash.now[:alert] = "プロフィールを作成できませんでした"
    render :new, status: :unprocessable_entity
  end

  def edit
    @hobbies_text = @profile.profile_hobbies
                           .includes(hobby: { hobby_parent_tags: :parent_tag })
                           .map { |profile_hobby| serialize_profile_hobby(profile_hobby) }
                           .to_json
  end

  def update
    @profile.hobbies_text = profile_params[:hobbies_text]

    ApplicationRecord.transaction do
      @profile.update!(profile_params.except(:hobbies_text))
      @profile.update_hobbies_from_json(@profile.hobbies_text) if @profile.hobbies_text.present?
    end
    redirect_to profile_path(@profile), notice: "プロフィールを更新しました"
  rescue ActiveRecord::RecordInvalid
    @hobbies_text = @profile.hobbies_text
    flash.now[:alert] = "プロフィールを更新できませんでした"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @profile.destroy
    redirect_to profiles_path, alert: "プロフィールを削除しました"
  end

  private

  def profile_params
    params.require(:profile).permit(:bio, :hobbies_text)
  end

  def redirect_if_profile_exists
    redirect_to profiles_path, notice: "プロフィールは作成済みです" if current_user.profile
  end

  def set_profile
    @profile = current_user.profile
    redirect_to new_my_profile_path, alert: "プロフィールを作成してください" unless @profile
  end

  def serialize_profile_hobby(profile_hobby)
    { name: profile_hobby.hobby.name, description: profile_hobby.description.to_s }
      .merge(profile_hobby.hobby.primary_parent_tag_info)
  end

  def set_parent_tags
    @parent_tags_json = ParentTag.where.not(slug: "uncategorized")
                                 .order(:room_type, :position)
                                 .group_by(&:room_type)
                                 .transform_values { |tags| tags.map { |t| { id: t.id, name: t.name } } }
                                 .to_json
  end
end
