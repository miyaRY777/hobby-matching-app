class ContactMailer < ApplicationMailer
  def notify(form)
    @form = form
    mail(
      to: ENV.fetch("CONTACT_EMAIL", "admin@example.com"),
      subject: "[お問い合わせ] #{form.subject}"
    )
  end
end
