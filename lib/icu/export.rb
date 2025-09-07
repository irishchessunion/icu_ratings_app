module ICU
  class Export
    def self.ratings
      @start = Time.now

      # Run the command that creates both export zip files. Perl is used because
      # it isn't so easy to create DBF files (for SwissPerfect) using Ruby.
      cmd = "bin/export.pl -e #{Rails.env} 2>&1"
      out = `#{cmd}`.strip

      # Initialise a report and a Boolean success for the Event we'll create later.
      report = []
      report.push cmd
      report.push "---"
      report.push out
      report.push "---"
      success = true

      # Update (or create) a Download object for each export file.
      begin
        %w(published live).each do |type|
          short = type == "published" ? "pub" : "live"
          file  = "tmp/#{short}.zip"
          match = "wrote #{file}"
          if out.index(match)
            action = self.write_to(short, type, file, 'zip')
            report.push "#{action} #{type} ratings download"
          else
            report.push "output doesn't match '#{match}'"
            success = false
          end

          file = short == "pub" ? "tmp/#{short}-#{Time.now.strftime('%b%y')}.xlsx" : "tmp/#{short}.xlsx"
          axlsx_package = Download.rating_list_xlsx(type)
          axlsx_package.serialize(file)
          action = self.write_to(short, type, file, 'xlsx')
          if action == 'created' and short == "pub"
            # Delete previous file
            old_file = "tmp/#{short}-#{1.month.ago.strftime('%b%y')}.xlsx"
            begin
              File.delete(old_file)
              report.push "deleted old file #{old_file}"
            rescue Errno::ENOENT
              report.push "could not delete old file #{old_file}"
            end
          end
          report.push "#{action} #{type} ratings download (xlsx)"
        end
      rescue => e
        report.push "EXCEPTION: #{e.message}"
        report += e.backtrace[0..10]
        success = false
      end

      # Create an Event to summarize what happened.
      Event.create(name: "Ratings Export", report: report.join("\n"), time: Time.now - @start, success: success)
    end
    
    # Reads the file from the tmp folder on the file system and either
    # creates or updates the relevant Download record in the database
    # @param short "pub" or "live" which is short for "published" and "live"
    # @param type "published" or "live"
    # @param file location of the download file on the system
    # @param extension "zip" or "xlsx", file extension of the download file
    def self.write_to(short, type, file, extension)
        comment      = "Latest #{type} ratings"
        file_name    = "#{short}_ratings.#{extension}"
        content_type = case extension
          when 'zip' then "application/zip"
          when 'xlsx' then "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          else "text/plain"
        end
        if type == "published"
          rating_list = RatingList.first
        else
          rating_list = nil
        end
        data         = File.open(file, "r", encoding: "ASCII-8BIT") { |f| f.read }
        download = Download.where(comment: comment, file_name: file_name, content_type: content_type, rating_list: rating_list).first
        if download
          action = "updated"
          download.data = data
          download.save!
        else
          action = "created"
          download = Download.create!(comment: comment, file_name: file_name, content_type: content_type, rating_list: rating_list, data: data)
        end
        action
    end
  end
end
