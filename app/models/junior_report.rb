class JuniorReport
  # @return [Array<String>] An array of CSV lines including the header
  def self.rows
    rows = ['ICU id,Name,Title,Fed,Rating,Full?,YOB,M/F,Club']
    IcuRatings::Juniors.new(under: 21).ratings.each do |r|
      rows << "#{r.icu_id},\"#{r.icu_player.last_name}, #{r.icu_player.first_name}\",\"#{r.icu_player.title}\",\"#{r.icu_player.fed}\",#{r.rating},#{r.full ? '' : 'Prov'},#{r.icu_player.dob.year},\"#{r.icu_player.gender}\",\"#{r.icu_player.club}\""
    end
    rows
  end

  def self.generate(filename)
    File.open(filename, 'w') do |f|
      f.write(rows.join("\n"))
    end
  end
end