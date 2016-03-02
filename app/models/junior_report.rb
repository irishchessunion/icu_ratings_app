class JuniorReport
  # @return [Array<String>] An array of CSV lines including the header
  def self.rows
    rows = ['ICU id,Name,Title,Fed,Rating,High Tide,Full?,YOB,M/F,Club']
    IcuRatings::Juniors.new(under: 21).ratings.each do |r|
      rows << row(r)
    end
    rows
  end

  # @param r [IcuRating]
  # @return [String] A row ready to put into the CSV file
  def self.row(r)
    name = "\"#{r.icu_player.last_name}, #{r.icu_player.first_name}\""
    title = r.icu_player.title
    fed = r.icu_player.fed
    hightide = r.icu_player.hightide(Date.new(2016, 1, 1), Date.new(2016, 4, 1)) || r.rating
    full_rating = r.full ? '' : 'Prov'
    yob = r.icu_player.dob.year
    gender = r.icu_player.gender
    club = "\"#{r.icu_player.club}\""
    [r.icu_id, name, title, fed, r.rating, hightide, full_rating, yob, gender, club].
        map {|val| val.to_s }.join(',')
  end

  def self.generate(filename)
    File.open(filename, 'w') do |f|
      f.write(rows.join("\n"))
    end
  end
end