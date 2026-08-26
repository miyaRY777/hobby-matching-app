class Mypage::ProfilesController < ApplicationController
  # 責務: 自分のプロフィール CRUD。趣味はタグ入力の JSON（hobbies_json）経由。公開閲覧は ProfilesController。
  before_action :authenticate_user!
  before_action :redirect_if_profile_exists, only: %i[new create]
  before_action :set_profile, only: %i[edit update destroy]
  before_action :set_parent_tags, only: %i[new create edit update]

  def new
    @profile = current_user.build_profile
  end

  def create
    # hobbies_json は attr_accessor（DBカラムではない）なので mass assignment から外して別途セットする
    @profile = current_user.build_profile(profile_params.except(:hobbies_json))
    @profile.hobbies_json = profile_params[:hobbies_json]

    # プロフィール保存と趣味の紐付けを同一トランザクションにする
    ApplicationRecord.transaction do
      @profile.save!
      @profile.update_hobbies_from_json(@profile.hobbies_json)
    end
    redirect_to mypage_root_path, notice: "プロフィールを作成しました"
  rescue ActiveRecord::RecordInvalid
    @hobbies_json = @profile.hobbies_json
    flash.now[:alert] = "プロフィールを作成できませんでした"
    render :new, status: :unprocessable_entity
  end

  def edit
    # タグ入力の初期値用。N+1 を防ぐ includes を維持する
    @hobbies_json = @profile.profile_hobbies
                           .includes(hobby: { hobby_parent_tags: :parent_tag })
                           .map { |profile_hobby| serialize_profile_hobby(profile_hobby) }
                           .to_json
  end

  def update
    # 先にセットしてバリデーション（更新時は hobbies_json があるときだけ趣味を検証する）
    @profile.hobbies_json = profile_params[:hobbies_json]

    ApplicationRecord.transaction do
      @profile.update!(profile_params.except(:hobbies_json))
      # 空のときは bio のみ更新を許可し、既存趣味は触らない
      @profile.update_hobbies_from_json(@profile.hobbies_json) if @profile.hobbies_json.present?
    end
    redirect_to profile_path(@profile), notice: "プロフィールを更新しました"
  rescue ActiveRecord::RecordInvalid
    @hobbies_json = @profile.hobbies_json
    flash.now[:alert] = "プロフィールを更新できませんでした"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @profile.destroy
    redirect_to profiles_path, alert: "プロフィールを削除しました"
  end

  private

  def profile_params
    params.require(:profile).permit(:bio, :hobbies_json)
  end

  def redirect_if_profile_exists
    redirect_to profiles_path, notice: "プロフィールは作成済みです" if current_user.profile
  end

  def set_profile
    @profile = current_user.profile
    redirect_to new_mypage_profile_path, alert: "プロフィールを作成してください" unless @profile
  end

  def serialize_profile_hobby(profile_hobby)
    { name: profile_hobby.hobby.name, description: profile_hobby.description.to_s }
      .merge(profile_hobby.hobby.primary_parent_tag_info)
  end

  def set_parent_tags
    # 未分類は選択させない。room_type ごとにタグ入力の親タグ候補を渡す
    @parent_tags_json = ParentTag.where.not(slug: "uncategorized")
                                 .order(:room_type, :position)
                                 .group_by(&:room_type)
                                 .transform_values { |tags| tags.map { |t| { id: t.id, name: t.name } } }
                                 .to_json
  end
end
