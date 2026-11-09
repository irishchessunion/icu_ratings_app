require "rails_helper"
require "tmpdir"
require "fileutils"

# Characterisation specs for lib/icu/export.rb.
#
# ICU::Export.ratings normally runs bin/export.pl (Perl), which writes the zip files
# into tmp/. The Perl command is stubbed here so these examples exercise only the
# Ruby side: the download records, the Excel workbook, and the event report.
describe ICU::Export do
  EXPECTED_HEADER = %w[ID_no Fide_no Name Title Fed Rtg_Nat Rtg_Int Games Birthday Sub Sex ClubName].freeze
  XLSX_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze
  ZIP_TYPE = "application/zip".freeze

  # Run each example from an empty directory, so the tmp/ files written by the
  # export never touch the real tmp/ directory of the repo.
  around(:each) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p("tmp")
        example.run
      end
    end
  end

  before(:each) do
    @list = RatingList.create!(date: Date.new(2026, 10, 1), tournament_cut_off: Date.new(2026, 10, 15), payment_cut_off: Date.new(2026, 10, 31))
    IcuRating.create!(list: @list.date, icu_id: 1001, rating: 1800)
    IcuPlayer.create!(id: 1001, first_name: "Ann", last_name: "Smith", deceased: false, fed: "IRL", gender: "F", dob: Date.new(1990, 5, 6), club: "Dublin")
    @month_yy = Time.now.strftime("%b%y")
    @old_month_yy = 1.month.ago.strftime("%b%y")
  end

  def write_fixture(path, content = "zip-bytes-#{path}")
    File.binwrite(path, content)
    content
  end

  # The command output that bin/export.pl prints when both files are written.
  def perl_success_output
    "wrote tmp/pub.zip\nwrote tmp/live.zip\n"
  end

  # Event has a default scope ordering by created_at, which only has one-second
  # resolution, so order by id to get the most recent event reliably.
  def latest_event
    Event.unscoped.order(:id).last
  end

  def stub_perl(output)
    allow(ICU::Export).to receive(:`).with("bin/export.pl -e test 2>&1").and_return(output)
  end

  # Writes the zip files that the stubbed Perl script would have produced.
  def write_zip_fixtures
    write_fixture("tmp/pub.zip")
    write_fixture("tmp/live.zip")
  end

  # Reads the first worksheet of an xlsx file and returns its rows as arrays of strings.
  def xlsx_rows(data)
    zip = Zip::File.open_buffer(StringIO.new(data))
    shared = []
    if (entry = zip.find_entry("xl/sharedStrings.xml"))
      Nokogiri::XML(entry.get_input_stream.read).xpath("//xmlns:si").each do |si|
        shared << si.xpath(".//xmlns:t").map(&:text).join
      end
    end
    sheet = Nokogiri::XML(zip.find_entry("xl/worksheets/sheet1.xml").get_input_stream.read)
    sheet.xpath("//xmlns:row").map do |row|
      row.xpath("./xmlns:c").map do |c|
        value = c.at_xpath("./xmlns:v")&.text
        if c["t"] == "s"
          shared[value.to_i]
        elsif c["t"] == "inlineStr"
          c.xpath(".//xmlns:t").map(&:text).join
        else
          value
        end
      end
    end
  end

  describe ".write_to" do
    it "creates a published download linked to the latest rating list" do
      data = write_fixture("tmp/pub.zip")
      action = ICU::Export.write_to("pub", "published", "tmp/pub.zip", "zip")
      expect(action).to eq("created")
      download = Download.last
      expect(download.comment).to eq("Latest published ratings")
      expect(download.file_name).to eq("pub_ratings.zip")
      expect(download.content_type).to eq(ZIP_TYPE)
      expect(download.rating_list).to eq(@list)
      expect(download.data).to eq(data)
    end

    it "creates a live download with no rating list" do
      write_fixture("tmp/live.zip")
      action = ICU::Export.write_to("live", "live", "tmp/live.zip", "zip")
      expect(action).to eq("created")
      download = Download.last
      expect(download.comment).to eq("Latest live ratings")
      expect(download.file_name).to eq("live_ratings.zip")
      expect(download.rating_list).to be_nil
    end

    it "uses the spreadsheet content type for xlsx files" do
      write_fixture("tmp/live.xlsx")
      ICU::Export.write_to("live", "live", "tmp/live.xlsx", "xlsx")
      expect(Download.last.content_type).to eq(XLSX_TYPE)
      expect(Download.last.file_name).to eq("live_ratings.xlsx")
    end

    it "updates the existing download rather than creating a second one" do
      write_fixture("tmp/live.zip", "first")
      ICU::Export.write_to("live", "live", "tmp/live.zip", "zip")
      write_fixture("tmp/live.zip", "second")
      action = ICU::Export.write_to("live", "live", "tmp/live.zip", "zip")
      expect(action).to eq("updated")
      expect(Download.count).to eq(1)
      expect(Download.last.data).to eq("second")
    end

    it "falls back to text/plain for any other extension" do
      write_fixture("tmp/live.txt")
      ICU::Export.write_to("live", "live", "tmp/live.txt", "txt")
      expect(Download.last.content_type).to eq("text/plain")
      expect(Download.last.file_name).to eq("live_ratings.txt")
    end

    it "stores the file bytes unchanged, including non-ASCII bytes" do
      bytes = [0xFF, 0xFE, 0x00, 0x80, 0xC3, 0xA9].pack("C*")
      File.binwrite("tmp/live.zip", bytes)
      ICU::Export.write_to("live", "live", "tmp/live.zip", "zip")
      expect(Download.last.data.b).to eq(bytes)
    end
  end

  describe ".ratings" do
    it "runs the Perl export for the test environment" do
      expect(ICU::Export).to receive(:`).with("bin/export.pl -e test 2>&1").and_return(perl_success_output)
      write_zip_fixtures
      ICU::Export.ratings
    end

    context "when the export succeeds" do
      before(:each) do
        stub_perl(perl_success_output)
        write_zip_fixtures
      end

      it "creates four downloads: zip and xlsx for published and live" do
        ICU::Export.ratings
        expect(Download.pluck(:file_name)).to match_array(%w[pub_ratings.zip pub_ratings.xlsx live_ratings.zip live_ratings.xlsx])
      end

      it "writes the published xlsx to a dated file and the live xlsx to a fixed file" do
        ICU::Export.ratings
        expect(File.exist?("tmp/pub-#{@month_yy}.xlsx")).to be true
        expect(File.exist?("tmp/live.xlsx")).to be true
      end

      it "records a successful event with the step-by-step report" do
        ICU::Export.ratings
        event = latest_event
        expect(event.name).to eq("Ratings Export")
        expect(event.success).to be true
        expect(event.time).to be >= 0
        lines = event.report.split("\n")
        expect(lines.first).to eq("bin/export.pl -e test 2>&1")
        expect(lines).to include("created published ratings download", "created published ratings download (xlsx)")
        expect(lines).to include("created live ratings download", "created live ratings download (xlsx)")
        expect(lines).to include("could not delete old file tmp/pub-#{@old_month_yy}.xlsx")
        expect(lines.none? { |line| line.start_with?("EXCEPTION") }).to be true
      end

      it "updates the downloads, rather than duplicating them, when run again" do
        ICU::Export.ratings
        ICU::Export.ratings
        expect(Download.count).to eq(4)
        report = latest_event.report
        expect(report).to include("updated published ratings download", "updated live ratings download")
        expect(latest_event.success).to be true
      end
    end

    it "deletes last month's published xlsx when a new one is created" do
      stub_perl(perl_success_output)
      write_zip_fixtures
      old_file = "tmp/pub-#{@old_month_yy}.xlsx"
      File.binwrite(old_file, "old")
      ICU::Export.ratings
      expect(File.exist?(old_file)).to be false
      expect(latest_event.report).to include("deleted old file #{old_file}")
    end

    it "records a failure when the Perl output doesn't mention the zip file" do
      stub_perl("some other output\n")
      write_zip_fixtures
      ICU::Export.ratings
      event = latest_event
      expect(event.success).to be false
      expect(event.report).to include("output doesn't match 'wrote tmp/pub.zip'")
      expect(event.report).to include("output doesn't match 'wrote tmp/live.zip'")
      expect(Download.pluck(:file_name)).to match_array(%w[pub_ratings.xlsx live_ratings.xlsx])
    end

    it "records a failure, with a backtrace, when an exception is raised" do
      stub_perl(perl_success_output)
      write_zip_fixtures
      allow(Download).to receive(:rating_list_xlsx).and_raise(RuntimeError, "boom")
      ICU::Export.ratings
      event = latest_event
      expect(event.success).to be false
      expect(event.report).to include("EXCEPTION: boom")
      expect(event.report.lines.size).to be > 3
    end
  end

  describe "the published and live Excel workbook" do
    before(:each) do
      stub_perl(perl_success_output)
      write_zip_fixtures
      ICU::Export.ratings
    end

    it "has the Swiss Manager header row" do
      rows = xlsx_rows(Download.find_by(file_name: "live_ratings.xlsx").data)
      expect(rows.first).to eq(EXPECTED_HEADER)
    end

    it "lists each icu player with their id, name, sex and club, and hides the date of birth" do
      rows = xlsx_rows(Download.find_by(file_name: "live_ratings.xlsx").data)
      expect(rows.size).to eq(2)
      data = rows.last
      expect(data[0]).to eq("1001")
      expect(data[2]).to eq("Smith, Ann")
      expect(data[4]).to eq("IRL")
      # The Rtg_Nat column comes from the player's rated results, not from icu_ratings,
      # so this player (who has no rated tournament) has no value.
      expect(data[5]).to be_nil
      expect(data[8]).to eq("1990/01/01")
      expect(data[9]).to eq("U")
      expect(data[10]).to eq("F")
      expect(data[11]).to eq("Dublin")
    end

    it "uses the published sheet name for the published workbook" do
      published = Download.find_by(file_name: "pub_ratings.xlsx").data
      zip = Zip::File.open_buffer(StringIO.new(published))
      workbook = Nokogiri::XML(zip.find_entry("xl/workbook.xml").get_input_stream.read)
      expect(workbook.xpath("//xmlns:sheet").first["name"]).to eq("Published Rating List")
    end
  end
end
