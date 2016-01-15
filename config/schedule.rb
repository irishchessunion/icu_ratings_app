set :output, "log/cron.log"
set :job_template, nil # set explicit PATH in crontab instead

every 1.minute do
  command "cd #{path}; F=tmp/#{@environment}_rating_run; if [ -f $F ]; then mv $F ${F}_; RAILS_ENV=#{@environment} bin/rake rating:run --silent; fi"
end

every :hour, at: 0 do
  rake "sync:players"
end

every :hour, at: "5" do
  rake "sync:users"
end

every :hour, at: 10 do
  rake "sync:fees"
end

every :hour, at: 15 do
  rake "sync:subs"
end

every :day, at: "5:30am" do
  rake "export:ratings"
end

every :sunday, at: "5:30am" do
  rake "sync:irish_fide_players"
end

every :sunday, at: "6:00am" do
  rake "sync:other_fide_players"
end
