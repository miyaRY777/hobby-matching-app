class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  # Email/password 認証に加えて、Google / Discord の OAuth ログインを許可する
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 discord]

  has_one :profile, dependent: :destroy
  has_many :social_accounts, dependent: :destroy
  has_one_attached :avatar

  validates :nickname, presence: true, length: { maximum: 20 }
  validates :avatar,
    content_type: %w[image/jpeg image/png image/gif image/webp],
    size: { less_than_or_equal_to: 5.megabytes }

  # 渡されたレコードの所有者が自分かどうかを判定する
  def own?(record)
    record.present? && record.user_id == id
  end

  # boolean カラムを読みやすい述語メソッドとして公開する
  def admin?
    admin
  end
end
