class ProfileSearchQuery
  # q  : 検索キーワード文字列（カンマ区切り）
  # mode: "and" or "or"
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @raw_query = params[:q].to_s.strip
    @mode      = params[:mode].to_s == "or" ? :or : :and
  end

  def call
    terms = @raw_query.split(",").map(&:strip).reject(&:blank?)
    return base_scope if terms.empty?

    ids = @mode == :and ? and_profile_ids(terms) : or_profile_ids(terms)
    base_scope.where(id: ids)
  end

  private

  # 全termにマッチする（趣味名 or nickname）プロフィールIDの積集合
  def and_profile_ids(terms)
    terms.map { |term| matched_ids_for(term) }.reduce(:&)
  end

  # いずれかのtermにマッチするプロフィールIDの和集合
  def or_profile_ids(terms)
    terms.flat_map { |term| matched_ids_for(term) }.uniq
  end

  # 1つのtermに対して「趣味名一致」または「nickname部分一致」するプロフィールID一覧
  def matched_ids_for(term)
    hobby_ids    = Hobby.where(name: term).pluck(:id)
    by_hobby     = ProfileHobby.where(hobby_id: hobby_ids).pluck(:profile_id)
    by_nickname  = Profile.joins(:user)
                          .where("users.nickname LIKE ?", "%#{sanitize_sql_like(term)}%")
                          .pluck(:id)
    (by_hobby + by_nickname).uniq
  end

  def base_scope
    Profile.includes(profile_hobbies: { hobby: :parent_tag }, user: { avatar_attachment: :blob }).order(created_at: :desc)
  end

  def sanitize_sql_like(str)
    ActiveRecord::Base.sanitize_sql_like(str)
  end
end
