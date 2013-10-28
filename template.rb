# coding: utf-8
dir = File.dirname(__FILE__)

gem 'slim-rails'
gem 'simple_form', github: 'plataformatec/simple_form', branch: 'master'
gem 'ransack'
gem 'kaminari'
gem 'active_decorator'

use_bootstrap = if yes?('Use Bootstrap?')
                  uncomment_lines 'Gemfile', "gem 'therubyracer'"
                  gem 'less-rails'
                  gem 'twitter-bootstrap-rails'
                  true
                else
                  false
                end

use_unicorn = if yes?('Use unicorn?')
                uncomment_lines 'Gemfile', "gem 'unicorn'"
                true
              else
                false
              end

gem 'whenever', require: false if yes?('Use whenever?')
use_devise = if yes?('Use devise?')
               gem 'devise'
               gem 'devise-i18n'
               devise_model = ask 'Please input devise model name. ex) User, Admin: '
               true
             else
               false
             end

use_cancan = if yes?('Use cancan?')
               gem 'cancan'
               true
             else
               false
             end

use_heroku = if yes?('Use heroku?')
               gem 'rails_12factor', group: :production
               true
             else
               false
             end

gem_group :development, :test do
  gem 'rspec-rails'
  gem "factory_girl_rails"
  gem 'capybara'
  gem 'capybara-webkit'
end

gem_group :development do
  gem 'pry-rails'
  gem 'parallel_tests'
  gem 'better_errors'
  gem "binding_of_caller"
  gem 'spring'
  gem 'letter_opener'
end

gem_group :test do
  gem 'database_cleaner'
  gem 'timecop'
  gem 'launchy'
  gem 'webmock', require: 'webmock/rspec'
end

run_bundle
generate 'rspec:install'
remove_dir 'test'

if use_bootstrap
  generate 'bootstrap:install', 'less'
  generate 'simple_form:install', '--bootstrap'
  if yes?("Use responsive layout?")
    generate 'bootstrap:layout', 'application fluid'
  else
    generate 'bootstrap:layout', 'application fixed'
  end
  remove_file 'app/views/layouts/application.html.erb'
else
  generate 'simple_form:install'
end

# Application settings
# ----------------------------------------------------------------
application do
  %Q{
    config.generators do |g|
      g.orm :active_record
      g.test_framework :rspec, fixture: true, fixture_replacement: :factory_girl
      g.view_specs false
      g.controller_specs false
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
  }
end

# Environment setting
# ----------------------------------------------------------------
comment_lines 'config/environments/production.rb', "config.serve_static_assets = false"
environment 'config.serve_static_assets = true', env: 'production'
environment 'config.action_mailer.delivery_method = :letter_opener', env: 'development'


# RSpec setting
# ----------------------------------------------------------------
remove_file 'spec'
directory File.expand_path('spec', dir), 'spec', recursive: true

if use_devise
  uncomment_lines 'spec/spec_helper.rb', 'include Warden::Test::Helpers'
  uncomment_lines 'spec/spec_helper.rb', 'config.include Devise::TestHelpers, type: :controller'
  uncomment_lines 'spec/spec_helper.rb', 'config.include Devise::TestHelpers, type: :view'
  uncomment_lines 'spec/spec_helper.rb', 'Warden.test_mode!'
  uncomment_lines 'spec/spec_helper.rb', 'Warden.test_reset!'
  generate 'devise:install'
end

if use_cancan
  generate 'cancan:ability'
end

append_to_file '.rspec' do
  "--format documentation\n--format ParallelTests::RSpec::FailuresLogger --out tmp/failing_specs.log"
end

# Unicorn setting
# ----------------------------------------------------------------
if use_unicorn
  copy_file File.expand_path('config/unicorn.rb', dir), 'config/unicorn.rb'
  create_file 'Procfile' do
    body = <<EOS
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
EOS
  end
else
  create_file 'Procfile' do
    body = <<EOS
web: bundle exec rails server -p $PORT
EOS
  end
end

create_file '.foreman' do
  body = <<EOS
port: 3000
EOS
end

# .gitignore settings
# ----------------------------------------------------------------
remove_file '.gitignore'
create_file '.gitignore' do
  body = <<EOS
/.bundle
/db/*.sqlite3
/log/*.log
/tmp
.DS_Store
/public/assets*
/config/database.yml
newrelic.yml
.foreman
.env
doc/
*.swp
*~
.project
.idea
.secret
/*.iml
EOS
end

# Root path settings
# ----------------------------------------------------------------
generate 'controller', 'home index'
route "root to: 'home#index'"



# Create directories
# ----------------------------------------------------------------
empty_directory 'app/decorators'
create_file 'app/decorators/.gitkeep'

# Database settings
# ----------------------------------------------------------------
case gem_for_database
  when 'pg', 'mysql2'
    run "sed -i -e \"s/#{app_name}_test/#{app_name}_test<%= ENV[\\'TEST_ENV_NUMBER\\']%>/g\" config/database.yml"
  when 'sqlite3'
    run "sed -i -e \"s/db\\/test.sqlite3/db\\/test<%= ENV[\\'TEST_ENV_NUMBER\\']%>.sqlite3/g\" config/database.yml"
  else
end

run "cp config/database.yml config/database.yml.sample"

case gem_for_database
  when 'pg'
    run "createuser -h localhost -d #{app_name}"
  else
end

rake 'db:drop'
rake 'db:create'
rake 'db:migrate'
rake 'parallel:create'
rake 'parallel:prepare'

# git
# ----------------------------------------------------------------
git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }

# Bitbucket
# ----------------------------------------------------------------
use_bitbucket = if yes?('Push Bitbucket?')
                  git_uri = `git config remote.origin.url`.strip
                  if git_uri.size == 0
                    username = ask "What is your Bitbucket username?"
                    password = ask "What is your Bitbucket password?"
                    run "curl -k -X POST --user #{username}:#{password} 'https://api.bitbucket.org/1.0/repositories' -d 'name=#{app_name}&is_private=true'"
                    git remote: "add origin git@bitbucket.org:#{username}/#{app_name}.git"
                    git push: 'origin master'
                  else
                    say "Repository already exists:"
                    say "#{git_uri}"
                  end
                  true
                else
                  false
                end

if use_heroku
  if yes?('Deploy heroku staging?')
    run 'heroku create --remote staging'
    git push: 'staging master'
  end
end

if use_devise
  environment "config.action_mailer.default_url_options = { host: 'localhost:3000' }", env: 'development'
  environment "config.action_mailer.default_url_options = { host: 'localhost:3000' }", env: 'test'
  generate "devise #{devise_model}"
  generate 'devise:views'
  git add: "."
  git commit: %Q{ -m 'Add devise model and views.' }
  if use_bitbucket
    git push: 'origin master'
  end
  puts "!!! Please set up #{devise_model} migration file and rake db:migrate !!!"
end
exit