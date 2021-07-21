namespace :mail do
  desc "Send a test email"
  task test: :environment do
    Emailer.test_email.deliver_now
  end
end

