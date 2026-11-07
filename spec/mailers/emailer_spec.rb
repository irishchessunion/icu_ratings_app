require "rails_helper"

describe Emailer do
  context "#notify_tournament_uploaded" do
    before(:each) do
      @u = FactoryBot.create(:user, role: "reporter")
      @t = test_tournament("bunratty_masters_2011.tab", @u.id)
      @n = ActionMailer::Base.deliveries.size
    end

    it "should send notification to rating officer" do
      email = Emailer.notify_tournament_uploaded(@t).deliver_now
      expect(ActionMailer::Base.deliveries.size).to eq(@n + 1)
      expect(email.to).to include("ratings@icu.ie")
      expect(email.from).to include("NO-REPLY@icu.ie")
      expect(email.subject).to eq("New Tournament Uploaded")
      expect(email.body).to include("Name: #{@t.name}")
      expect(email.body).to include("Start: #{@t.start.to_s(:db)}")
      expect(email.body).to include("Finish: #{@t.finish.to_s(:db)}")
      expect(email.body).to include("Reporter: #{@u.name(false)}")
      expect(email.body).to include("Uploaded: #{@t.created_at.to_s(:db)}")
      expect(email.body).to include("Link: http://ratings.icu.ie/admin/tournaments/#{@t.id}")
    end
  end

  context "#test_email" do
    it "sends a test email to the given address" do
      n = ActionMailer::Base.deliveries.size
      email = Emailer.test_email("foo@example.com").deliver_now
      expect(ActionMailer::Base.deliveries.size).to eq(n + 1)
      expect(email.to).to include("foo@example.com")
      expect(email.subject).to eq("Test of Mail Server")
    end

    it "defaults to ratings@icu.ie" do
      email = Emailer.test_email.deliver_now
      expect(email.to).to include("ratings@icu.ie")
    end
  end
end
