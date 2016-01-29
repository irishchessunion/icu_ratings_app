desc 'Install assets that should not be pre-compiled'
task :install_non_compiled_assets do
  on roles(fetch(:assets_roles)) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        source = release_path.join('app', 'assets', 'images', 'images')
        target = release_path.join('public', fetch(:assets_prefix), 'images')
        run "echo cp #{source}/* #{target}"
        #execute :rake, "assets:precompile"
      end
    end
  end
end

after 'deploy:compile_assets', 'install_non_compiled_assets'
