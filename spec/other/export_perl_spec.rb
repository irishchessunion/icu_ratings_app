require "rails_helper"
require "open3"
require "tmpdir"
require "dbf"

# Characterisation specs for bin/export.pl, the Perl script that writes the
# published and live ratings downloads (SwissPerfect DBF and Swiss Manager text,
# zipped together). These run the real script against a small, fixed dataset in
# the test database, and check the output format and the business rules it applies.
#
# The script uses its own database connection, so the data must be committed:
# hence truncation: true.
#
# The season names depend on today's date (the script works out the season from
# the clock), so they're calculated here the same way.
describe "bin/export.pl", truncation: true do
  # Season logic from the script: a new season starts in August.
  def season_for(year, month)
    y = month < 8 ? year - 1 : year
    "#{y}-#{format("%02d", (y + 1) % 100)}"
  end

  let(:now) { Time.now }
  let(:this_season) { season_for(now.year, now.month) }
  let(:mmyy) { now.strftime("%b%y") }

  # Swiss Manager line layout: "%-8s  %-32s  %-2s  %3s  %-4s  %3d  %-4s  %s"
  def sm_line(id, name, title, fed, rating, year, flags)
    [id.to_s.ljust(8), "  ", name.ljust(32), "  ", title.ljust(2), "  ", fed.rjust(3),
     "  ", rating.to_s.ljust(4), "  ", "0".rjust(3), "  ", year.ljust(4), "  ", flags].join + "\n"
  end

  def run_export(dir)
    Open3.capture2e("perl", "bin/export.pl", "-e", "test", "-f", dir)
  end

  def read_dbf(path)
    table = DBF::Table.new(path)
    table.map { |record| record.attributes.transform_values { |v| v.to_s.strip } }
  end

  before(:each) do
    @list = RatingList.create!(date: Date.new(2026, 10, 1), tournament_cut_off: Date.new(2026, 10, 15), payment_cut_off: Date.new(2026, 10, 31))
    IcuRating.create!(list: Date.new(2026, 10, 1), icu_id: 1001, rating: 1900)

    # Players in the export.
    IcuPlayer.create!(id: 1001, first_name: "Ann", last_name: "Smith", deceased: false, fed: "IRL", gender: "F", dob: Date.new(1990, 5, 6), club: "Dublin Westwood")
    IcuPlayer.create!(id: 1002, first_name: "David", last_name: "Murray", deceased: false, fed: "IRL", gender: "M", club: "Dublin", title: "IM")
    IcuPlayer.create!(id: 1003, first_name: "Timer", last_name: "Old", deceased: false)
    IcuPlayer.create!(id: 1004, first_name: "Eve", last_name: "Adams", deceased: false, fed: "IRL", gender: "F", title: "WIM")

    # Players left out: deceased, and merged into a master record.
    IcuPlayer.create!(id: 1005, first_name: "Gone", last_name: "Away", deceased: true)
    IcuPlayer.create!(id: 1006, first_name: "Merged", last_name: "Dup", deceased: false, master_id: 1001)

    # Subscriptions: Smith has this season's online subscription, Murray is a lifetime member.
    Subscription.create!(icu_id: 1001, season: this_season, category: "online")
    Subscription.create!(icu_id: 1002, category: "lifetime")

    # Legacy rating for a player with no rated tournament.
    OldRating.create!(icu_id: 1003, rating: 1700, games: 12)

    # Rated tournaments: T1 finishes before the cut-off, T2 after it, so only live includes T2.
    t1 = Tournament.new(original_name: "Rated 1", name: "Rated 1", start: "2026-09-08", finish: "2026-10-10", rorder: 1, rounds: 6, user_id: 100, stage: "rated")
    t1.save!
    t2 = Tournament.new(original_name: "Rated 2", name: "Rated 2", start: "2026-10-18", finish: "2026-10-20", rorder: 2, rounds: 6, user_id: 100, stage: "rated")
    t2.save!

    save_tournament_player(t1, 1001, 1900)
    save_tournament_player(t1, 1002, 2100)
    save_tournament_player(t2, 1001, 1920)
  end

  def save_tournament_player(t, icu_id, rating)
    p = Player.new(first_name: "x", last_name: "x", original_name: "x", icu_id: icu_id, new_rating: rating, num: 1, tournament_id: t.id, category: "icu_player")
    p.save!(validate: false)
  end

  describe "run output" do
    it "reports the list, cut-off and last rated tournament, and the counts of each type of rating" do
      out, status = run_export(Dir.mktmpdir)
      expect(status.exitstatus).to eq(0)
      expect(out).to include("last list: 2026-10-01")
      expect(out).to include("tournament cut-off date: 2026-10-15")
      expect(out).to include("last tournament rating order number: 1")
      expect(out).to include("4     players")
      expect(out).to include("2     subscriptions")
      expect(out).to include("2     initial published ratings")
      expect(out).to include("3     augmented published ratings")
      expect(out).to include("2     initial live ratings")
      expect(out).to include("3     augmented live ratings")
    end

    it "writes the zip, DBF and text files for both published and live" do
      dir = Dir.mktmpdir
      out, _ = run_export(dir)
      %w[pub live].each do |short|
        expect(out).to match(%r{wrote #{dir}/swiss_perfect_#{short}\.dbf \(\d+\)})
        expect(out).to match(%r{wrote #{dir}/swiss_manager_#{short}\.#{mmyy}\.txt \(\d+\)})
        expect(out).to match(%r{wrote #{dir}/#{short}\.zip \(\d+\)})
      end
    end
  end

  describe "published SwissPerfect DBF" do
    before(:each) { @dir = Dir.mktmpdir; run_export(@dir) }

    it "has the expected fields, in order" do
      table = DBF::Table.new("#{@dir}/swiss_perfect_pub.dbf")
      expect(table.columns.map(&:name)).to eq(%w[ICU_CODE FIRST_NAME LAST_NAME ICU_RATING SEX CLUB DOB])
    end

    it "lists players by last name then first name, with the published rating, sex, club and date of birth" do
      rows = read_dbf("#{@dir}/swiss_perfect_pub.dbf")
      expect(rows).to eq([
        { "ICU_CODE" => "1004", "FIRST_NAME" => "Eve", "LAST_NAME" => "Adams", "ICU_RATING" => "0", "SEX" => "F", "CLUB" => "U", "DOB" => "" },
        { "ICU_CODE" => "1002", "FIRST_NAME" => "David", "LAST_NAME" => "Murray", "ICU_RATING" => "2100", "SEX" => "M", "CLUB" => "L Dublin", "DOB" => "" },
        { "ICU_CODE" => "1003", "FIRST_NAME" => "Timer", "LAST_NAME" => "Old", "ICU_RATING" => "1700", "SEX" => "", "CLUB" => "U", "DOB" => "" },
        { "ICU_CODE" => "1001", "FIRST_NAME" => "Ann", "LAST_NAME" => "Smith", "ICU_RATING" => "1900", "SEX" => "F", "CLUB" => "S Dublin Westwood", "DOB" => "06-05-1990" },
      ])
    end
  end

  describe "live SwissPerfect DBF" do
    before(:each) { @dir = Dir.mktmpdir; run_export(@dir) }

    it "uses the rating from the latest rated tournament, including tournaments after the cut-off" do
      rows = read_dbf("#{@dir}/swiss_perfect_live.dbf")
      smith = rows.find { |r| r["ICU_CODE"] == "1001" }
      murray = rows.find { |r| r["ICU_CODE"] == "1002" }
      expect(smith["ICU_RATING"]).to eq("1920")
      expect(murray["ICU_RATING"]).to eq("2100")
    end
  end

  describe "Swiss Manager text file" do
    before(:each) { @dir = Dir.mktmpdir; run_export(@dir) }

    it "has the header row" do
      lines = File.readlines("#{@dir}/swiss_manager_pub.#{mmyy}.txt", encoding: "UTF-8")
      expect(lines.first).to eq("ID number Name                              TitlFed  #{mmyy} GamesBorn  Flag\n")
    end

    it "writes one line per player, with title, federation, rating, year of birth and flags" do
      lines = File.readlines("#{@dir}/swiss_manager_pub.#{mmyy}.txt", encoding: "UTF-8")
      expect(lines.drop(1)).to eq([
        sm_line(1004, "Adams, Eve", "wi", "IRL", "", "", "wU"),
        sm_line(1002, "Murray, David", "i", "IRL", 2100, "", "L Dublin"),
        sm_line(1003, "Old, Timer", "", "", 1700, "", "U"),
        sm_line(1001, "Smith, Ann", "", "IRL", 1900, "1990", "wS Dublin Uestuood"),
      ])
    end

    it "replaces W and w with U and u in the club, but leaves the names alone" do
      lines = File.readlines("#{@dir}/swiss_manager_pub.#{mmyy}.txt", encoding: "UTF-8")
      smith = lines.find { |l| l.start_with?("1001") }
      expect(smith).to include("Dublin Uestuood")
      expect(smith).to include("Smith, Ann")
    end
  end

  describe "zip archive" do
    before(:each) { @dir = Dir.mktmpdir; run_export(@dir) }

    it "contains the DBF and text files for each list, with the same bytes as on disk" do
      %w[pub live].each do |short|
        names = ["swiss_perfect_#{short}.dbf", "swiss_manager_#{short}.#{mmyy}.txt"]
        Zip::File.open("#{@dir}/#{short}.zip") do |zip|
          expect(zip.entries.map(&:name)).to match_array(names)
          names.each do |name|
            expect(zip.find_entry(name).get_input_stream.read.b).to eq(File.binread("#{@dir}/#{name}"))
          end
        end
      end
    end
  end
end
