server '178.79.157.117', user: "dmurray", roles: %w{web app db}

desc "show ruby version"
task :show_ruby_version do
  on roles(:web) do |host|
    execute "echo $(date) > /tmp/cap.txt"
    execute "echo $(pwd) >> /tmp/cap.txt"
    execute 'echo $(ruby --version) >> /tmp/cap.txt'
    execute "echo $(which ruby) >> /tmp/cap.txt"
    execute "echo $PATH >> /tmp/cap.txt"
    execute "echo $TEST_VAR >> /tmp/cap.txt"
    execute "echo $SHELL >> /tmp/cap.txt"
    execute "echo $0 >> /tmp/cap.txt"
    execute "test.sh >> /tmp/cap.txt"
  end
end
