class Emailer < ActionMailer::Base
  def notify_tournament_uploaded(tournament)
    @tournament = tournament
    mail(to: "ratings@icu.ie", subject: "New Tournament Uploaded")
  end

  def test_email(email_to=nil)
    @email_to = email_to || 'ratings@icu.ie'
    mail(to: @email_to, subject: "Test of Mail Server")
  end
end
