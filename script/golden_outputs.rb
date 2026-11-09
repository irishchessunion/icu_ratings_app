# Golden output generator for the ICU ratings app.
#
# Captures the current calculation behaviour for a fixed set of tournament
# inputs so upgrade stages can diff against the baseline.
#
# Usage:
#   RAILS_ENV=test bundle exec rails runner script/golden_outputs.rb [folder]
#
# The optional folder name (e.g. "Upgrade00") selects the output subdirectory
# under golden/; a bare run writes to golden/ itself.
#
# Output: golden/<folder>/<input_name>.txt (one file per input). Not committed to git.

require "fileutils"

raise "Run this script with RAILS_ENV=test" unless Rails.env.test?

User.pulls_disabled = true if defined?(User)

INPUTS = %w[
  bunratty_masters_2011.tab
  junior_championships_u19_2010.txt
  armstrong_2012_with_bom.tab
  isle_of_man_2007.csv
  rathmines_senior_2011.zip
].freeze

# Output directory: pass as first arg (e.g. "Upgrade00") or set GOLDEN_DIR env.
# Outputs always live under golden/. A bare run writes to golden/ itself.
arg = (ARGV.first || ENV["GOLDEN_DIR"]).to_s
arg = arg.sub(%r{^golden/}, "")
OUT_DIR = arg.empty? ? Rails.root.join("golden") : Rails.root.join("golden", arg)
FileUtils.mkdir_p(OUT_DIR)

def test_file_path(name)
  Rails.root.join("spec/files/#{name}").to_s
end

def get_parser(file)
  parser = case file
    when /\.txt$/ then "SPExport"
    when /\.zip$/ then "SwissPerfect"
    when /\.tab$/ then "Krause"
    when /\.csv$/ then "ForeignCSV"
  end
  "ICU::Tournament::#{parser}".constantize.new
end

def load_tournament(file, user_id)
  opt = {}
  case file
  when "bunratty_masters_2011.tab", "kilkenny_masters_2011.tab"
    opt[:fide] = true
  when "junior_championships_u19_2010.txt"
    opt[:start] = "2010-04-11"
    opt[:name] = "U-19 All Ireland"
  when "junior_championships_u19_2010.zip"
    opt[:start] = "2010-04-11"
  end
  parser = get_parser(file)
  icut = begin
    parser.parse_file!(test_file_path(file), opt)
  rescue ArgumentError
    parser.parse_file!(test_file_path(file))
  end
  tournament = Tournament.build_from_icut(icut)
  tournament.user_id = user_id
  tournament.save!
  tournament.upload = FactoryBot.create(:upload, name: file, user_id: user_id, tournament_id: tournament.id)
  tournament.save!
  tournament.renumber_opponents
  tournament
end

INPUTS.each do |file|
  # Clean slate per input.
  DatabaseCleaner.clean_with(:truncation) if defined?(DatabaseCleaner)

  # Reload ICU players and old ratings so tournament players match existing records.
  icu_players_cache = YAML.load(File.read(Rails.root.join("spec/factories/icu_players.yml")))
  icu_players_cache.each { |id, data| FactoryBot.create(:icu_player, data.merge(id: id)) }
  old_ratings_cache = YAML.load(File.read(Rails.root.join("spec/factories/old_ratings.yml")))
  old_ratings_cache.each do |icu_id, data|
    FactoryBot.create(:old_rating, icu_id: icu_id, rating: data[0], games: data[1], full: data[2])
  end

  user = FactoryBot.create(:user, role: "admin")
  tournament = load_tournament(file, user.id)

  out = []
  out << "GOLDEN OUTPUT"
  out << "input: #{file}"
  out << "commit: #{`git rev-parse HEAD`.strip rescue 'unknown'}"
  out << "ruby: #{RUBY_VERSION}"
  out << "rails: #{Rails.version}"
  out << ""
  out << "=== TOURNAMENT ==="
  out << "name: #{tournament.name}"
  out << "start: #{tournament.start}"
  out << "rounds: #{tournament.rounds}"
  out << "status: #{tournament.status}"

  # Move to a rateable stage, then rate.
  tournament.move_stage("ready", user)
  tournament.move_stage("queued", user)
  err = tournament.rate
  out << "rate_result: #{err.nil? ? 'ok' : err}"

  out << ""
  out << "=== PLAYERS (sorted by id) ==="
  tournament.players.reload.sort_by(&:id).each do |p|
    out << "#{p.id}\t#{p.name}\tstart=#{p.start_rating}\tend=#{p.new_rating rescue p.end_rating rescue nil}\trg=#{p.rateable_games}\trs=#{p.rateable_score}\taor=#{p.ave_opp_rating}\tpr=#{p.performance_rating}"
  end

  out << ""
  out << "=== KRAUSE EXPORT ==="
  begin
    out << tournament.export("type" => "Krause")
  rescue => e
    out << "ERROR: #{e.message}"
  end

  File.write(OUT_DIR.join("#{File.basename(file, '.*')}.txt"), out.join("\n") + "\n")
  puts "wrote #{OUT_DIR.join(File.basename(file, '.*') + '.txt')}"
end
