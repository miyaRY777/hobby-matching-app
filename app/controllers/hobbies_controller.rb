class HobbiesController < ApplicationController
  before_action :authenticate_user!

  def autocomplete
    q = params[:q].to_s.strip
    return render json: [] if q.length < 2

    hobbies = Hobby.where("normalized_name LIKE ?", "#{Hobby.normalize(q)}%")
                   .includes(hobby_parent_tags: :parent_tag)
                   .limit(10)

    render json: hobbies.map { |hobby| serialize_hobby(hobby) }
  end

  private

  def serialize_hobby(hobby)
    { name: hobby.name }.merge(hobby.primary_parent_tag_info)
  end
end
