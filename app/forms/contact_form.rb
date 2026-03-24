class ContactForm
  include ActiveModel::Model

  attr_accessor :name, :email, :subject, :body

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :body, presence: true
end
