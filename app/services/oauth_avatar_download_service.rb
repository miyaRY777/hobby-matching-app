class OauthAvatarDownloadService
  def self.call(user:, auth:)
    new(user: user, auth: auth).call
  end

  def initialize(user:, auth:)
    @user = user
    @auth = auth
  end

  def call
    return if @user.avatar.attached?

    image_url = @auth.info&.image
    return if image_url.blank?

    download_and_attach(image_url)
  rescue StandardError
    # DL失敗時も認証を妨げない
    nil
  end

  private

  def download_and_attach(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    content_type = response["Content-Type"]
    extension = content_type&.split("/")&.last || "jpg"
    filename = "oauth_avatar.#{extension}"

    @user.avatar.attach(
      io: StringIO.new(response.body),
      filename: filename,
      content_type: content_type
    )
  end
end
