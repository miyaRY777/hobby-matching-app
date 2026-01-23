class ProfilesController < ApplicationController
  before_action :authenticate_user! # 誰？
  before_action :redirect_if_profile_exists, only: %i[new create] # 作れる？
  before_action :set_profile, only: %i[edit update destroy] # どれ？

  def new
    @profile = current_user.build_profile
  end

  def create
    @profile = current_user.build_profile(profile_params)
    if @profile.save
      #TODO あとでroot_path → profiles_pathに変更
      redirect_to root_path, notice: "プロフィールを作成しました"
    else
      flash.now[:alert] = "プロフィールを作成できませんでした"
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @profiles = Profile.includes(:user)
  end

  def show
    @profile = Profile.find_by(id: params[:id])
    redirect_to profiles_path unless @profile
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path(@profile), notice: "プロフィールを更新しました"
    else
      flash.now[:alert] = "プロフィールを更新できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @profile.destroy
    redirect_to profiles_path, alert: "プロフィールを削除しました"
  end

  private

  def profile_params
    params.require(:profile).permit(:bio)
  end

  def redirect_if_profile_exists
    redirect_to profiles_path, notice: "プロフィールは作成済みです" if current_user.profile
  end

  def set_profile
    @profile = current_user.profile
    redirect_to new_my_profile_path,  alert: "プロフィールを作成してください" unless @profile
  end
end
