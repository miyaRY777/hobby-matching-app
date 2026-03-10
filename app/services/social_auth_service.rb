class SocialAuthService
  Result = Struct.new(:success?, :user, :error_message, keyword_init: true)

  def self.call(auth)
    new(auth).call
  end

  def initialize(auth)
    @auth = auth
  end

  def call
    # 1. 既存 SocialAccount を検索
    existing = SocialAccount.includes(:user).find_by(provider: provider, uid: uid)
    return success(existing.user) if existing

    # 2. email / email_verified チェック
    return failure("メールアドレスが取得できませんでした") if email.blank?
    return failure("メールアドレスが検証されていません") unless email_verified?

    # 3. 同一メールの既存ユーザーを検索
    user = User.find_by(email: email)

    if user
      user.social_accounts.create!(provider: provider, uid: uid)
      return success(user)
    end

    # 4. 新規ユーザー + SocialAccount を作成
    user = create_user_with_social_account
    success(user)
  rescue ActiveRecord::RecordNotUnique
    # 5. 競合時: 再取得
    existing = SocialAccount.includes(:user).find_by!(provider: provider, uid: uid)
    success(existing.user)
  end

  private

  def provider
    @auth.provider
  end

  def uid
    @auth.uid
  end

  def email
    @auth.info.email
  end

  def nickname
    name = @auth.info.name.to_s.strip
    if name.blank?
      "user_#{SecureRandom.hex(4)}"
    else
      name.truncate(20, omission: "")
    end
  end

  def email_verified?
    verified = @auth.dig("extra", "id_info", "email_verified")
    verified = @auth.dig("extra", "raw_info", "email_verified") if verified.nil?
    ActiveModel::Type::Boolean.new.cast(verified)
  end

  def create_user_with_social_account
    ActiveRecord::Base.transaction do
      user = User.create!(
        email: email,
        password: Devise.friendly_token[0, 20],
        nickname: nickname
      )
      user.social_accounts.create!(provider: provider, uid: uid)
      user
    end
  end

  def success(user)
    Result.new(success?: true, user: user, error_message: nil)
  end

  def failure(message)
    Result.new(success?: false, user: nil, error_message: message)
  end
end
