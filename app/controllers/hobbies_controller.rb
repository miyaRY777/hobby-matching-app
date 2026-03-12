class HobbiesController < ApplicationController
  before_action :authenticate_user!

  def autocomplete
    q = params[:q].to_s.strip

    if q.length < 2
      render json: []
      return
    end

    hobbies = Hobby.where("name LIKE ?", "#{q.downcase}%").limit(10).pluck(:name)
    render json: hobbies
  end
end
