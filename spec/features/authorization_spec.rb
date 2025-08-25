require 'rails_helper'

describe "authorized links for" do
  %w[guest member reporter organiser officer admin].each do |role|
    describe "#{role}s" do
      before(:each) do
        role == "guest" ? visit("/home") : login(role)
      end

      after(:each) do
        visit "/log_out" unless role == "guest"
      end

      {
        "/admin/events"            => %w[admin officer],
        "/admin/failures"          => %w[admin],
        "/admin/fees"              => %w[admin officer],
        "/admin/fide_player_files" => %w[admin officer],
        "/admin/logins"            => %w[admin],
        "/admin/new_players"       => %w[admin officer],
        "/admin/old_ratings"       => %w[admin officer organiser reporter],
        "/admin/old_tournaments"   => %w[admin officer organiser reporter],
        "/admin/rating_lists"      => %w[admin officer],
        "/admin/rating_runs"       => %w[admin officer],
        "/admin/subscriptions"     => %w[admin officer],
        "/admin/tournaments"       => %w[admin officer organiser reporter],
        "/admin/uploads"           => %w[admin officer organiser reporter],
        "/admin/uploads/new"       => %w[admin officer organiser reporter],
        "/admin/users"             => %w[admin],
        "/articles"                => %w[admin officer organiser reporter member guest],
        "/articles/new"            => %w[admin officer],
        "/contacts"                => %w[admin officer organiser reporter member guest],
        "/downloads"               => %w[admin officer organiser reporter],
        "/downloads/new"           => %w[admin officer],
        "/federations"             => %w[admin officer organiser reporter member guest],
        "/fide_players"            => %w[admin officer organiser reporter],
        "/fide_ratings"            => %w[admin officer organiser reporter member guest],
        "/home"                    => %w[admin officer organiser reporter member guest],
        "/icu_players"             => %w[admin officer organiser],
        "/icu_ratings"             => %w[admin officer organiser reporter member guest],
        "/icu_ratings/war"         => %w[admin officer organiser reporter member],
        "/icu_ratings/juniors"     => %w[admin officer organiser reporter member],
        "/live_ratings"            => %w[admin officer organiser reporter member],
        "/my_home"                 => %w[admin officer organiser reporter member],
        "/overview"                => %w[admin officer organiser reporter],
        "/system_info"             => %w[admin],
        "/tournaments"             => %w[admin officer organiser reporter member guest],
      }.each do |target, authorized|
        if authorized.include?(role)
          it "get link to and can follow #{target}" do
            expect(page).to have_xpath("//a[@href='#{target}']")
            visit target
            expect(page).to_not have_selector("span.alert", :text => /authoriz/i)
          end
        else
          it "get no link to and can't follow #{target}" do
            expect(page).to_not have_xpath("//a[@href='#{target}']")
            visit target
            expect(page).to have_selector("span.alert", :text => /authoriz/i)
          end
        end
      end
    end
  end
end

describe "authorized to follow" do
  %w[guest member reporter officer admin].each do |role|
    describe "#{role}s" do
      before(:each) do
        FactoryBot.create(:icu_player, id: 1)
        role == "guest" ? visit("/home") : login(role)
      end

      after(:each) do
        visit "/log_out" unless role == "guest"
      end

      {
        "/their_home/1" => %w[admin officer reporter],
      }.each do |target, authorized|
        if authorized.include?(role)
          it "can follow #{target}" do
            visit target
            expect(page).to_not have_selector("span.alert", :text => /authoriz/i)
          end
        else
          it "can't follow #{target}" do
            visit target
            expect(page).to have_selector("span.alert", :text => /authoriz/i)
          end
        end
      end
    end
  end
end
