require 'rails_helper'

describe ICU::Database do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  describe "#get_user" do
    let(:db) { ICU::Database::Pull.allocate }

    before do
      db.instance_variable_set(:@client, mysql_client)
    end

    it "returns user hash when valid and verified" do
      allow(mysql_client).to receive(:query).with(/users.*WHERE id = 123/).and_return([
        { email: "a@b.com", status: "OK", encrypted_password: "a" * 32, salt: "b" * 32, expires_on: Date.new(2026, 12, 31), verified_at: Time.now }
      ])
      result = db.get_user(123, "a@b.com")
      expect(result).to include(password: "a" * 32, salt: "b" * 32, status: "ok")
    end

    it "returns 'pending' status when verified_at is blank" do
      allow(mysql_client).to receive(:query).and_return([
        { email: "a@b.com", status: "OK", encrypted_password: "a" * 32, salt: "b" * 32, expires_on: Date.today, verified_at: nil }
      ])
      expect(db.get_user(123, "a@b.com")[:status]).to eq("pending")
    end

    it "returns error when not found" do
      allow(mysql_client).to receive(:query).and_return([])
      expect(db.get_user(1, "x")).to eq("couldn't find user with ID 1")
    end

    it "returns error when multiple found" do
      allow(mysql_client).to receive(:query).and_return([{}, {}])
      expect(db.get_user(1, "x")).to match(/found more than one/)
    end

    it "returns error on email mismatch" do
      allow(mysql_client).to receive(:query).and_return([{ email: "b@b.com", status: "OK", encrypted_password: "a" * 32, salt: "b" * 32 }])
      expect(db.get_user(1, "a@b.com")).to match(/expected email/)
    end

    it "returns error when status != OK" do
      allow(mysql_client).to receive(:query).and_return([{ email: "a@b.com", status: "inactive", encrypted_password: "a" * 32, salt: "b" * 32 }])
      expect(db.get_user(1, "a@b.com")).to match(/expected status OK/)
    end

    it "returns error when password missing" do
      allow(mysql_client).to receive(:query).and_return([{ email: "a@b.com", status: "OK", encrypted_password: nil, salt: "b" * 32 }])
      expect(db.get_user(1, "a@b.com")).to match(/expected password/)
    end

    it "returns error when password too short" do
      allow(mysql_client).to receive(:query).and_return([{ email: "a@b.com", status: "OK", encrypted_password: "short", salt: "b" * 32 }])
      expect(db.get_user(1, "a@b.com")).to match(/32 character password/)
    end

    it "returns error when salt missing" do
      allow(mysql_client).to receive(:query).and_return([{ email: "a@b.com", status: "OK", encrypted_password: "a" * 32, salt: nil }])
      expect(db.get_user(1, "a@b.com")).to match(/expected salt/)
    end

    it "returns error when salt too short" do
      allow(mysql_client).to receive(:query).and_return([{ email: "a@b.com", status: "OK", encrypted_password: "a" * 32, salt: "short" }])
      expect(db.get_user(1, "a@b.com")).to match(/32 character salt/)
    end

    it "rescues Mysql2::Error" do
      allow(mysql_client).to receive(:query).and_raise(Mysql2::Error.new("boom"))
      expect(db.get_user(1, "x")).to match(/mysql error/)
    end

    it "rescues other errors" do
      allow(mysql_client).to receive(:query).and_raise(StandardError.new("oops"))
      expect(db.get_user(1, "x")).to match(/error:/)
    end
  end

  describe "helpers" do
    let(:db) { ICU::Database::Pull.allocate }

    before do
      db.instance_variable_set(:@client, mysql_client)
    end

    it "#summarize_list" do
      expect(db.send(:summarize_list, nil)).to eq("none")
      expect(db.send(:summarize_list, [])).to eq("none")
      expect(db.send(:summarize_list, [1, 2, 3])).to eq("3: 1, 2, 3")
      expect(db.send(:summarize_list, (1..10).to_a)).to eq("10: 1, 2, 3, 4, 5 ... 10")
    end

    it "#summarize_changes" do
      expect(db.send(:summarize_changes)).to eq("none")
      db.instance_variable_set(:@changes, {})
      expect(db.send(:summarize_changes)).to eq("none")
      db.instance_variable_set(:@changes, { b: 2, a: 1 })
      expect(db.send(:summarize_changes)).to eq("a: 1, b: 2")
    end
  end
end


describe ICU::Database::Push do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:push) { ICU::Database::Push.new }

  describe "#update_user" do
    it "returns nil if nothing to update" do
      expect(push.update_user(1, "e", nil, nil, nil)).to be_nil
    end

    it "validates password length" do
      expect(push.update_user(1, "e", "short", "b" * 32, nil)).to match(/invalid password/)
    end

    it "validates salt length" do
      expect(push.update_user(1, "e", "a" * 32, "short", nil)).to match(/invalid salt/)
    end

    it "validates status" do
      expect(push.update_user(1, "e", "a" * 32, "b" * 32, "bad")).to match(/invalid status/)
    end

    it "returns error if user not found" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([])
      expect(push.update_user(1, "e", "a" * 32, "b" * 32, nil)).to match(/couldn't find user/)
    end

    it "returns error if more than one found" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([{}, {}])
      result = push.update_user(1, "e", "a" * 32, "b" * 32, nil)
      expect(result.to_s).to match(/found more than one|ms|error/)
    end

    it "returns error if email mismatch" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([{ email: "x@y.com", status: "OK" }])
      expect(push.update_user(1, "e@e.com", "a" * 32, "b" * 32, nil)).to match(/expected email/)
    end

    it "returns error if status != OK" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([{ email: "e", status: "pending" }])
      expect(push.update_user(1, "e", "a" * 32, "b" * 32, nil)).to match(/can't update/)
    end

    it "updates password and salt" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([{ email: "e", status: "OK", encrypted_password: "old", salt: "old", verified_at: nil }])
      expect(mysql_client).to receive(:query).with(/UPDATE users SET.*encrypted_password.*salt/).and_return(nil)
      expect(push.update_user(1, "e", "a" * 32, "b" * 32, nil)).to be_nil
    end

    it "sets verified_at when status ok and not verified" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([{ email: "e", status: "OK", encrypted_password: "a" * 32, salt: "b" * 32, verified_at: nil }])
      expect(mysql_client).to receive(:query).with(/verified_at = '/).and_return(nil)
      expect(push.update_user(1, "e", "a" * 32, "b" * 32, "ok")).to be_nil
    end

    it "clears verified_at when status pending" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([{ email: "e", status: "OK", encrypted_password: "a" * 32, salt: "b" * 32, verified_at: Time.now }])
      allow(mysql_client).to receive(:query).with(/UPDATE/).and_return(nil)
      result = push.update_user(1, "e", "a" * 32, "b" * 32, "pending")
      expect(result).to be_nil
    end
  end

  describe "#update_player_rating" do
    it "updates rating" do
      allow(mysql_client).to receive(:query).with(/SELECT.*players/).and_return([{ id: 123 }])
      expect(mysql_client).to receive(:query).with(/UPDATE players SET latest_rating = 1500/).and_return(nil)
      expect(push.update_player_rating(123, 1500)).to be_nil
    end

    it "returns error if not found" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([])
      expect(push.update_player_rating(123, 1500)).to match(/couldn't find player/)
    end

    it "returns error if multiple found" do
      allow(mysql_client).to receive(:query).with(/SELECT/).and_return([{}, {}])
      expect(push.update_player_rating(123, 1500)).to match(/found more than one/)
    end

    it "rescues Mysql2::Error" do
      allow(mysql_client).to receive(:query).and_raise(Mysql2::Error.new("boom"))
      expect(push.update_player_rating(123, 1500)).to match(/mysql error/)
    end
  end

  describe ".sync_players_rating" do
    it "creates Event with success" do
      allow(IcuRating).to receive(:maximum).with(:list).and_return(Date.new(2026, 10, 1))
      rating = double("IcuRating", icu_id: 123, rating: 1500)
      allow(IcuRating).to receive(:where).with(list: Date.new(2026, 10, 1)).and_return([rating])
      push_instance = double("Push")
      allow(ICU::Database::Push).to receive(:new).and_return(push_instance)
      allow(push_instance).to receive(:update_player_rating).with(123, 1500).and_return(nil)
      expect(Event).to receive(:create).with(hash_including(name: "Push Player Ratings Synchronisation", success: true))
      ICU::Database::Push.sync_players_rating
    end

    it "marks success false if there are errors" do
      allow(IcuRating).to receive(:maximum).with(:list).and_return(Date.new(2026, 10, 1))
      rating = double("IcuRating", icu_id: 123, rating: 1500)
      allow(IcuRating).to receive(:where).with(list: Date.new(2026, 10, 1)).and_return([rating])
      push_instance = double("Push")
      allow(ICU::Database::Push).to receive(:new).and_return(push_instance)
      allow(push_instance).to receive(:update_player_rating).with(123, 1500).and_return("error")
      expect(Event).to receive(:create).with(hash_including(name: "Push Player Ratings Synchronisation", success: false))
      ICU::Database::Push.sync_players_rating
    end
  end
end


describe ICU::Database::Pull::Player do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Player.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#sync" do
    it "logs success" do
      allow(pull).to receive(:sync_players_steps).and_return(true)
      expect(Event).to receive(:create).with(hash_including(success: true))
      pull.sync
    end

    it "logs failure with report" do
      allow(pull).to receive(:sync_players_steps).and_return(false)
      allow(pull).to receive(:report).and_return("error: x")
      expect(Event).to receive(:create).with(hash_including(success: false))
      pull.sync
    end
  end

  describe "#sync_players_steps" do
    it "returns true on success" do
      allow(pull).to receive(:get_our_players)
      allow(pull).to receive(:get_their_players)
      allow(pull).to receive(:update_ours_from_theirs)
      expect(pull.send(:sync_players_steps)).to eq(true)
    end

    it "returns false on SyncError" do
      allow(pull).to receive(:get_our_players).and_raise(ICU::Database::Pull::SyncError.new("bad"))
      expect(pull.send(:sync_players_steps)).to eq(false)
      expect(pull.instance_variable_get(:@error).to_s).to include("bad")
    end

    it "returns false on generic error" do
      allow(pull).to receive(:get_our_players).and_raise(StandardError.new("oops"))
      expect(pull.send(:sync_players_steps)).to eq(false)
      expect(pull.instance_variable_get(:@error).to_s).to include("oops")
    end
  end

  describe "#get_their_players" do
    it "maps fields and concatenates phones, deceased becomes true" do
      rows = [{ id: 1, first_name: "A", last_name: "B", dob: "1990-01-01", joined: "2000-01-01", fed: "IRL", status: "deceased", home_phone: "111", work_phone: "222", mobile_phone: "", player_id: nil, club: "Dublin" }]
      allow(mysql_client).to receive(:query).and_return(rows)
      pull.send(:get_their_players)
      p = pull.instance_variable_get(:@their_players)[1]
      expect(p[:deceased]).to eq(true)
      expect(p[:phone_numbers]).to include("home: 111")
    end
  end

  describe "#update_ours_from_theirs" do
    it "creates new IcuPlayer when missing" do
      pull.instance_variable_set(:@our_players, {})
      pull.instance_variable_set(:@their_players, { 5 => { first_name: "A", last_name: "B", deceased: false } })
      icu = double("IcuPlayer")
      allow(IcuPlayer).to receive(:new).and_yield(icu).and_return(icu)
      allow(icu).to receive(:id=)
      allow(icu).to receive(:valid?).and_return(true)
      allow(icu).to receive(:changed?).and_return(true)
      allow(icu).to receive(:save!)
      pull.send(:update_ours_from_theirs)
      expect(pull.instance_variable_get(:@creates)).to include(5)
    end

    it "updates existing, tracks changes" do
      icu = double("IcuPlayer", changed?: true, valid?: true, changed: ["first_name"])
      allow(icu).to receive(:send)
      allow(icu).to receive(:save!)
      pull.instance_variable_set(:@our_players, { 1 => icu })
      pull.instance_variable_set(:@their_players, { 1 => { first_name: "X" } })
      pull.send(:update_ours_from_theirs)
      expect(pull.instance_variable_get(:@updates)).to include(1)
    end

    it "raises SyncError when invalid" do
      icu = double("IcuPlayer", changed?: false, valid?: false, inspect: "#<IcuPlayer:xxx>")
      allow(icu).to receive(:send)
      pull.instance_variable_set(:@our_players, { 1 => icu })
      pull.instance_variable_set(:@their_players, { 1 => {} })
      expect { pull.send(:update_ours_from_theirs) }.to raise_error(ICU::Database::Pull::SyncError)
    end
  end

  describe "#report" do
    it "includes creates/updates/changes/error" do
      pull.instance_variable_set(:@creates, [1, 2, 3])
      pull.instance_variable_set(:@updates, [])
      pull.instance_variable_set(:@changes, { first_name: 2 })
      pull.instance_variable_set(:@error, "bad")
      report = pull.send(:report)
      expect(report).to include("creates:")
      expect(report).to include("updates:")
      expect(report).to include("changes:")
      expect(report).to include("error: bad")
    end
  end
end


describe ICU::Database::Pull::User do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::User.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
    pull.instance_variable_set(:@our_players, { 10 => double })
  end

  describe "#get_their_users" do
    it "maps verified_at to status ok/pending, filters bad icu ids and bad emails" do
      rows = [
        { id: 1, email: "a@b.com", encrypted_password: "p", salt: "s", player_id: 10, expires_on: Date.today, verified_at: Time.now },
        { id: 2, email: "bad-email", encrypted_password: "p", salt: "s", player_id: 10, expires_on: Date.today, verified_at: nil },
        { id: 3, email: "c@d.com", encrypted_password: "p", salt: "s", player_id: 999, expires_on: Date.today, verified_at: Time.now },
      ]
      allow(mysql_client).to receive(:query).and_return(rows)
      pull.send(:get_their_users)
      users = pull.instance_variable_get(:@their_users)
      expect(users[1][:status]).to eq("ok")
      expect(users.key?(2)).to eq(false)
      expect(users.key?(3)).to eq(false)
      expect(pull.instance_variable_get(:@bad_icu_ids)).to include(999)
      expect(pull.instance_variable_get(:@bad_emails).first).to include("2|")
    end
  end

  describe "#update_ours_from_theirs" do
    it "creates new user with id set" do
      user = double("User")
      allow(user).to receive(:valid?).and_return(true)
      allow(user).to receive(:changed?).and_return(true)
      allow(user).to receive(:id).and_return(nil)
      allow(user).to receive(:id=)
      allow(user).to receive(:save!)
      allow(user).to receive(:email=)
      allow(user).to receive(:status=)
      allow(::User).to receive(:new).and_return(user)
      pull.instance_variable_set(:@our_users, {})
      pull.instance_variable_set(:@their_users, { 100 => { email: "a@b.com", status: "ok" } })
      pull.send(:update_ours_from_theirs)
      expect(pull.instance_variable_get(:@creates)).to include(100)
    end

    it "updates existing user and tracks changes" do
      user = double("User", valid?: true, changed?: true, changed: ["email"], id: 50)
      allow(user).to receive(:send)
      allow(user).to receive(:save!)
      pull.instance_variable_set(:@our_users, { 50 => user })
      pull.instance_variable_set(:@their_users, { 50 => { email: "new@b.com" } })
      pull.send(:update_ours_from_theirs)
      expect(pull.instance_variable_get(:@updates)).to include(50)
    end
  end

  describe "#report" do
    it "includes all fields" do
      pull.instance_variable_set(:@our_users, {})
      pull.instance_variable_set(:@their_users, {})
      pull.instance_variable_set(:@ours_not_theirs, [])
      pull.instance_variable_set(:@theirs_not_ours, [])
      pull.instance_variable_set(:@bad_emails, [])
      pull.instance_variable_set(:@creates, [])
      pull.instance_variable_set(:@updates, [])
      pull.instance_variable_set(:@changes, {})
      pull.instance_variable_set(:@bad_icu_ids, [])
      report = pull.send(:report)
      expect(report).to include("our users")
    end
  end
end


describe ICU::Database::Pull::Item do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Item.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#adjust" do
    it "parses description and date from YAML notes" do
      item = { notes: "- Tournament Name\n- '2026-05-01'\nother" }
      pull.send(:adjust, item)
      expect(item[:category]).to eq("FTR")
      expect(item[:status]).to eq("Completed")
      expect(item[:description]).to eq("Tournament Name")
      expect(item[:date]).to eq("2026-05-01")
    end

    it "maps refunded to Refunded" do
      item = { status: "refunded", notes: "- X\n- '2026-01-01'" }
      pull.send(:adjust, item)
      expect(item[:status]).to eq("Refunded")
    end

    it "raises when parsing fails" do
      item = { notes: "garbage" }
      expect { pull.send(:adjust, item) }.to raise_error(/can't parse note/)
    end
  end

  describe "#remove_legacy_fees" do
    it "deletes legacy fees with id < 400" do
      rel = double
      allow(Fee).to receive(:where).with(category: "FTR").and_return(rel)
      allow(rel).to receive(:where).with("id < 400").and_return(rel)
      expect(rel).to receive(:delete_all).and_return(5)
      pull.send(:remove_legacy_fees)
      expect(pull.instance_variable_get(:@legacy_deletes)).to eq(5)
    end
  end

  describe "#get_their_items" do
    it "adjusts items and maps keys" do
      rows = [{ id: 1, status: "paid", player_id: 10, notes: "- T\n- '2026-01-01'" }]
      allow(mysql_client).to receive(:query).and_return(rows)
      pull.instance_variable_set(:@their_items, {})
      pull.send(:get_their_items)
      items = pull.instance_variable_get(:@their_items)
      expect(items[1][:category]).to eq("FTR")
      expect(items[1][:icu_id]).to eq(10)
      expect(items[1][:description]).to eq("T")
    end
  end

  describe "#update_ours_from_theirs" do
    it "creates new fee" do
      fee = double("Fee")
      allow(fee).to receive(:valid?).and_return(true)
      allow(fee).to receive(:changed?).and_return(true)
      allow(fee).to receive(:id).and_return(nil)
      allow(fee).to receive(:id=)
      allow(fee).to receive(:save!)
      allow(fee).to receive(:used=)
      allow(fee).to receive(:new_record?).and_return(true)
      allow(fee).to receive(:icu_id=)
      allow(Fee).to receive(:new).and_return(fee)
      pull.instance_variable_set(:@our_fees, {})
      pull.instance_variable_set(:@their_items, { 100 => { icu_id: 10 } })
      pull.send(:update_ours_from_theirs)
      expect(pull.instance_variable_get(:@creates)).to include(100)
    end
  end

  describe "#report" do
    it "includes all fields" do
      pull.instance_variable_set(:@our_fees, {})
      pull.instance_variable_set(:@their_items, {})
      pull.instance_variable_set(:@legacy_deletes, 0)
      pull.instance_variable_set(:@creates, [])
      pull.instance_variable_set(:@updates, [])
      pull.instance_variable_set(:@changes, {})
      report = pull.send(:report)
      expect(report).to include("our fees")
    end
  end
end


describe ICU::Database::Pull::Subs do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Subs.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#get_season" do
    it "validates and sets season" do
      pull.send(:get_season, "2023-24")
      expect(pull.instance_variable_get(:@season)).to eq("2023-24")
      expect(pull.instance_variable_get(:@season_start)).to eq("2023-09-01")
    end

    it "uses Subscription.season if nil" do
      allow(Subscription).to receive(:season).and_return("2024-25")
      pull.send(:get_season, nil)
      expect(pull.instance_variable_get(:@season)).to eq("2024-25")
    end

    it "raises on invalid season" do
      expect { pull.send(:get_season, "2025-27") }.to raise_error(ICU::Database::Pull::SyncError)
    end
  end

  describe "#do_creates_and_updates" do
    before do
      pull.instance_variable_set(:@our_subs, [[], {}])
      pull.instance_variable_set(:@their_subs, [[], {}])
      pull.instance_variable_set(:@creates, [[], []])
      pull.instance_variable_set(:@updates, [[], []])
      pull.instance_variable_set(:@thesame, [[], []])
    end

    it "prefers online over offline" do
      pull.instance_variable_set(:@their_subs, [[], { 1 => [{ category: "offline" }, { category: "online" }] }])
      expect(Subscription).to receive(:create!).with(hash_including(category: "online"))
      pull.send(:do_creates_and_updates)
    end

    it "destroys and recreates when category changes" do
      osub = double("Subscription", category: "offline")
      allow(osub).to receive(:destroy)
      pull.instance_variable_set(:@our_subs, [[], { 1 => [osub] }])
      pull.instance_variable_set(:@their_subs, [[], { 1 => [{ category: "online" }] }])
      expect(Subscription).to receive(:create!)
      pull.send(:do_creates_and_updates)
      expect(osub).to have_received(:destroy)
    end

    it "creates new subscription" do
      pull.instance_variable_set(:@their_subs, [[], { 7 => [{ category: "online", icu_id: 7, pay_date: Date.today }] }])
      expect(Subscription).to receive(:create!)
      pull.send(:do_creates_and_updates)
    end
  end

  describe "#do_deletes" do
    it "deletes local subs not present remotely" do
      sub = double("Subscription")
      allow(sub).to receive(:destroy)
      pull.instance_variable_set(:@our_subs, [[], { 5 => [sub] }])
      pull.instance_variable_set(:@their_subs, [[], {}])
      pull.send(:do_deletes)
      expect(sub).to have_received(:destroy)
    end
  end

  describe "#report" do
    it "includes all fields" do
      pull.instance_variable_set(:@season, "2025-2026")
      pull.instance_variable_set(:@our_subs, [{}, {}])
      pull.instance_variable_set(:@our_dups, [[], []])
      pull.instance_variable_set(:@their_subs, [{}, {}])
      pull.instance_variable_set(:@their_dups, [[], []])
      pull.instance_variable_set(:@creates, [[], []])
      pull.instance_variable_set(:@updates, [[], []])
      pull.instance_variable_set(:@thesame, [[], []])
      pull.instance_variable_set(:@deletes, [[], []])
      report = pull.send(:report)
      expect(report).to include("season")
    end
  end
end


describe ICU::Database::Pull::Stats do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Stats.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
    pull.send(:setup)
  end

  describe "#get_www_stats" do
    it "categorizes and marks duplicates" do
      rows = [
        { id: 1, player_id: nil, status: "active", source: "import" },
        { id: 2, player_id: 1, status: "active", source: "import" },
      ]
      allow(mysql_client).to receive(:query).and_return(rows)
      pull.send(:get_www_stats)
      expect(pull.instance_variable_get(:@www_stats)["active"]["import"].include?(1)).to eq(true)
      expect(pull.instance_variable_get(:@www_stats)["duplicate"]["import"].include?(2)).to eq(true)
    end

    it "raises on invalid status" do
      rows = [{ id: 1, player_id: nil, status: "bad", source: "import" }]
      allow(mysql_client).to receive(:query).and_return(rows)
      expect { pull.send(:get_www_stats) }.to raise_error(/invlid status/)
    end

    it "raises on invalid source" do
      rows = [{ id: 1, player_id: nil, status: "active", source: "bad" }]
      allow(mysql_client).to receive(:query).and_return(rows)
      expect { pull.send(:get_www_stats) }.to raise_error(/invlid source/)
    end
  end

  describe "helpers" do
    it "#center formats numbers and strings" do
      expect(pull.send(:center, str: "hi")).to include("hi")
      expect(pull.send(:center, str: 5)).to include("5")
    end

    it "#row joins with sep" do
      expect(pull.send(:row, ["a", "b"])).to eq("|a|b|")
    end
  end
end


describe ICU::Database::Pull::User do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::User.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
    pull.instance_variable_set(:@our_players, { 10 => double })
  end

  describe "#get_our_users" do
    it "builds hash of our users" do
      u1 = double("User", id: 1)
      u2 = double("User", id: 2)
      allow(::User).to receive(:all).and_return([u1, u2])
      pull.send(:get_our_users)
      expect(pull.instance_variable_get(:@our_users)[1]).to eq(u1)
      expect(pull.instance_variable_get(:@our_users)[2]).to eq(u2)
    end
  end

  describe "#stats" do
    it "computes differences" do
      pull.instance_variable_set(:@our_users, { 1 => double, 2 => double })
      pull.instance_variable_set(:@their_users, { 2 => double, 3 => double })
      pull.send(:stats)
      expect(pull.instance_variable_get(:@ours_not_theirs)).to include(1)
      expect(pull.instance_variable_get(:@theirs_not_ours)).to include(3)
    end
  end

  describe "#sql" do
    it "returns sql" do
      expect(pull.send(:sql)).to include("FROM users")
    end
  end

  describe "#sync_user_steps" do
    it "returns true on success" do
      allow(pull).to receive(:get_our_players)
      allow(pull).to receive(:get_our_users)
      allow(pull).to receive(:get_their_users)
      allow(pull).to receive(:update_ours_from_theirs)
      allow(pull).to receive(:stats)
      allow(pull).to receive(:report)
      expect(pull.send(:sync_user_steps)).to eq(true)
    end

    it "returns false on SyncError" do
      allow(pull).to receive(:get_our_players).and_raise(ICU::Database::Pull::SyncError.new("bad"))
      expect(pull.send(:sync_user_steps)).to eq(false)
    end

    it "returns false on generic error" do
      allow(pull).to receive(:get_our_players).and_raise(StandardError.new("oops"))
      expect(pull.send(:sync_user_steps)).to eq(false)
    end
  end

  describe "#sync" do
    it "logs success" do
      allow(pull).to receive(:sync_user_steps).and_return(true)
      expect(Event).to receive(:create).with(hash_including(success: true))
      pull.sync
    end
  end
end


describe ICU::Database::Pull::Item do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Item.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#get_our_fees" do
    it "builds hash of fees" do
      f1 = double("Fee", id: 1)
      allow(Fee).to receive(:all).and_return([f1])
      pull.send(:get_our_fees)
      expect(pull.instance_variable_get(:@our_fees)[1]).to eq(f1)
    end
  end

  describe "#sql" do
    it "returns sql" do
      expect(pull.send(:sql)).to include("FROM items")
    end
  end

  describe "#sync_item_steps" do
    it "returns true on success" do
      allow(pull).to receive(:remove_legacy_fees)
      allow(pull).to receive(:get_our_fees)
      allow(pull).to receive(:get_their_items)
      allow(pull).to receive(:update_ours_from_theirs)
      expect(pull.send(:sync_item_steps)).to eq(true)
    end

    it "returns false on SyncError" do
      allow(pull).to receive(:remove_legacy_fees).and_raise(ICU::Database::Pull::SyncError.new("bad"))
      expect(pull.send(:sync_item_steps)).to eq(false)
    end

    it "returns false on generic error" do
      allow(pull).to receive(:remove_legacy_fees).and_raise(StandardError.new("oops"))
      expect(pull.send(:sync_item_steps)).to eq(false)
    end
  end

  describe "#sync" do
    it "logs success" do
      allow(pull).to receive(:sync_item_steps).and_return(true)
      expect(Event).to receive(:create).with(hash_including(success: true))
      pull.sync
    end
  end
end


describe ICU::Database::Pull::Subs do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Subs.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#get_our_subs" do
    it "builds hashes" do
      s1 = double("Subscription", icu_id: 1)
      allow(Subscription).to receive(:where).and_return([s1])
      pull.send(:get_our_subs)
      expect(pull.instance_variable_get(:@our_subs)[0]).to be_a(Hash)
      expect(pull.instance_variable_get(:@our_subs)[1]).to be_a(Hash)
    end
  end

  describe "#check_our_dups" do
    it "finds duplicates" do
      sub = double("Subscription")
      pull.instance_variable_set(:@our_subs, [{ 1 => [sub, sub] }, {}])
      pull.send(:check_our_dups)
      expect(pull.instance_variable_get(:@our_dups)[0]).to include(1)
    end
  end

  describe "#get_their_subs" do
    it "fetches from db" do
      rows = [{ icu_id: 5, pay_date: Date.today }]
      allow(mysql_client).to receive(:query).and_return(rows)
      pull.instance_variable_set(:@season, "2023-24")
      pull.instance_variable_set(:@season_start, "2023-09-01")
      pull.send(:get_their_subs)
      expect(pull.instance_variable_get(:@their_subs)[0]).to be_a(Hash)
      expect(pull.instance_variable_get(:@their_subs)[1]).to be_a(Hash)
    end
  end

  describe "#check_their_dups" do
    it "finds duplicates" do
      pull.instance_variable_set(:@their_subs, [{ 1 => [1, 2] }, {}])
      pull.send(:check_their_dups)
      expect(pull.instance_variable_get(:@their_dups)[0]).to include(1)
    end
  end

  describe "#sql" do
    it "returns sql" do
      pull.instance_variable_set(:@season_start, "2023-09-01")
      expect(pull.send(:sql, "online")).to include("paypal")
      expect(pull.send(:sql, "offline")).to include("cheque")
      expect(pull.send(:sql, "lifetime")).to include("start_date IS NULL")
    end
  end

  describe "#sync_subs_steps" do
    it "returns true on success" do
      allow(pull).to receive(:get_season)
      allow(pull).to receive(:get_our_subs)
      allow(pull).to receive(:check_our_dups)
      allow(pull).to receive(:get_their_subs)
      allow(pull).to receive(:check_their_dups)
      allow(pull).to receive(:do_creates_and_updates)
      allow(pull).to receive(:do_deletes)
      expect(pull.send(:sync_subs_steps, nil)).to eq(true)
    end

    it "returns false on SyncError" do
      allow(pull).to receive(:get_season).and_raise(ICU::Database::Pull::SyncError.new("bad"))
      expect(pull.send(:sync_subs_steps, nil)).to eq(false)
    end

    it "returns false on generic error" do
      allow(pull).to receive(:get_season).and_raise(StandardError.new("oops"))
      expect(pull.send(:sync_subs_steps, nil)).to eq(false)
    end
  end

  describe "#sync" do
    it "logs success" do
      allow(pull).to receive(:sync_subs_steps).and_return(true)
      expect(Event).to receive(:create).with(hash_including(success: true))
      pull.sync
    end
  end
end


describe ICU::Database::Pull::Player do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Player.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#get_our_players" do
    it "builds hash" do
      p1 = double("IcuPlayer", id: 1)
      allow(IcuPlayer).to receive(:all).and_return([p1])
      pull.send(:get_our_players)
      expect(pull.instance_variable_get(:@our_players)[1]).to eq(p1)
    end
  end

  describe "#players_sql" do
    it "returns sql" do
      expect(pull.send(:players_sql)).to include("FROM players")
    end
  end
end


describe ICU::Database::Pull::Stats do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Stats.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.send(:setup)
  end

  describe "#gather" do
    it "calls all gather methods" do
      allow(pull).to receive(:get_www_stats)
      allow(pull).to receive(:get_rat_stats)
      allow(pull).to receive(:get_plr_stats)
      allow(pull).to receive(:get_usr_stats)
      allow(pull).to receive(:get_lst_stats)
      allow(pull).to receive(:get_leg_stats)
      allow(pull).to receive(:get_old_stats)
      pull.send(:gather)
      expect(pull).to have_received(:get_www_stats)
    end
  end

  describe "#get_rat_stats" do
    it "computes intersections" do
      pull.instance_variable_get(:@www_stats)["active"]["import"] = Set.new([1, 2])
      rel = double
      allow(IcuPlayer).to receive(:all).and_return(rel)
      allow(rel).to receive(:pluck).with(:id).and_return([1])
      pull.send(:get_rat_stats)
      expect(pull.instance_variable_get(:@rat_stats)["active"]["import"].include?(1)).to eq(true)
    end
  end

  describe "#get_plr_stats" do
    it "computes intersections" do
      pull.instance_variable_get(:@www_stats)["active"]["import"] = Set.new([1])
      rel = double
      allow(::Player).to receive(:where).and_return(rel)
      allow(rel).to receive(:not).with(icu_id: nil).and_return(rel)
      allow(rel).to receive(:pluck).with(:icu_id).and_return([1])
      pull.send(:get_plr_stats)
      expect(pull.instance_variable_get(:@plr_stats)).to be_a(Hash)
    end
  end

  describe "#get_usr_stats" do
    it "computes intersections" do
      pull.instance_variable_get(:@www_stats)["active"]["import"] = Set.new([1])
      rel = double
      allow(::User).to receive(:all).and_return(rel)
      allow(rel).to receive(:pluck).with(:icu_id).and_return([1])
      pull.send(:get_usr_stats)
      expect(pull.instance_variable_get(:@usr_stats)).to be_a(Hash)
    end
  end

  describe "#get_lst_stats" do
    it "computes intersections" do
      pull.instance_variable_get(:@www_stats)["active"]["import"] = Set.new([1])
      rel = double
      allow(IcuRating).to receive(:all).and_return(rel)
      allow(rel).to receive(:pluck).with(:icu_id).and_return([1])
      pull.send(:get_lst_stats)
      expect(pull.instance_variable_get(:@lst_stats)).to be_a(Hash)
    end
  end

  describe "#get_leg_stats" do
    it "computes intersections" do
      pull.instance_variable_set(:@www_stats, pull.send(:instance_variable_get, :@www_stats))
      pull.instance_variable_get(:@www_stats)["active"]["import"] = Set.new([1])
      rel = double
      allow(OldRating).to receive(:all).and_return(rel)
      allow(rel).to receive(:pluck).with(:icu_id).and_return([1])
      pull.send(:get_leg_stats)
      expect(pull.instance_variable_get(:@leg_stats)).to be_a(Hash)
    end
  end

  describe "#get_old_stats" do
    it "computes intersections" do
      pull.instance_variable_get(:@www_stats)["active"]["import"] = Set.new([1])
      rel = double
      allow(OldRatingHistory).to receive(:all).and_return(rel)
      allow(rel).to receive(:pluck).with(:icu_player_id).and_return([1])
      pull.send(:get_old_stats)
      expect(pull.instance_variable_get(:@old_stats)).to be_a(Hash)
    end
  end

  describe "#players_sql" do
    it "returns sql" do
      expect(pull.send(:players_sql)).to include("FROM players")
    end
  end
end


describe ICU::Database::Pull::Player do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Player.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#sync full flow" do
    it "calls all steps and creates success event" do
      allow(pull).to receive(:get_our_players)
      allow(pull).to receive(:get_their_players)
      allow(pull).to receive(:update_ours_from_theirs)
      allow(pull).to receive(:report).and_return("report")
      expect(Event).to receive(:create).with(hash_including(name: "ICU Player Synchronisation", success: true))
      pull.sync
    end

    it "creates failure event when sync_players_steps returns false" do
      allow(pull).to receive(:sync_players_steps).and_return(false)
      allow(pull).to receive(:report).and_return("error: x")
      expect(Event).to receive(:create).with(hash_including(name: "ICU Player Synchronisation", success: false))
      pull.sync
    end
  end
end


describe ICU::Database::Pull::User do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::User.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#sync full flow" do
    it "calls all steps and creates success event" do
      allow(pull).to receive(:get_our_players)
      allow(pull).to receive(:get_our_users)
      allow(pull).to receive(:get_their_users)
      allow(pull).to receive(:update_ours_from_theirs)
      allow(pull).to receive(:stats)
      allow(pull).to receive(:report)
      expect(Event).to receive(:create).with(hash_including(name: "ICU User Synchronisation", success: true))
      pull.sync
    end
  end
end


describe ICU::Database::Pull::Item do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Item.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#sync full flow" do
    it "calls all steps and creates success event" do
      allow(pull).to receive(:remove_legacy_fees)
      allow(pull).to receive(:get_our_fees)
      allow(pull).to receive(:get_their_items)
      allow(pull).to receive(:update_ours_from_theirs)
      allow(pull).to receive(:report)
      expect(Event).to receive(:create).with(hash_including(name: "ICU Item Synchronisation", success: true))
      pull.sync
    end
  end
end


describe ICU::Database::Pull::Subs do
  let(:mysql_client) { double("Mysql2::Client") }
  let(:www_db_config) { { host: "x", username: "x", password: "x", database: "x" } }

  before do
    allow(Rails.application.secrets).to receive(:www_db).and_return(www_db_config)
    allow(Mysql2::Client).to receive(:new).with(www_db_config.symbolize_keys).and_return(mysql_client)
    allow(mysql_client).to receive(:query_options).and_return({})
  end

  let(:pull) { ICU::Database::Pull::Subs.new }

  before do
    pull.instance_variable_set(:@client, mysql_client)
    pull.instance_variable_set(:@start, Time.now)
  end

  describe "#sync full flow" do
    it "calls all steps and creates success event" do
      allow(pull).to receive(:get_season)
      allow(pull).to receive(:get_our_subs)
      allow(pull).to receive(:check_our_dups)
      allow(pull).to receive(:get_their_subs)
      allow(pull).to receive(:check_their_dups)
      allow(pull).to receive(:do_creates_and_updates)
      allow(pull).to receive(:do_deletes)
      allow(pull).to receive(:report)
      expect(Event).to receive(:create).with(hash_including(name: "ICU Subs Synchronisation", success: true))
      pull.sync
    end
  end
end
