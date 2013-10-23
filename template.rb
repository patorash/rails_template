# coding: utf-8
dir = File.dirname(__FILE__)

gem 'slim-rails'
gem 'simple_form', github: 'plataformatec/simple_form', branch: 'master'
gem 'ransack'
gem 'kaminari'

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
end

gem_group :test do
  gem 'database_cleaner'
  gem 'timecop'
  gem 'launchy'
  gem 'webmock', require: 'webmock/rspec'
end

run 'bundle install'
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

remove_file 'spec'
directory File.expand_path('spec', dir), 'spec', recursive: true

append_to_file '.rspec' do
  "--format documentation\n--format ParallelTests::RSpec::FailuresLogger --out tmp/failing_specs.log"
end

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
EOS
end

generate 'controller', 'home index'
route "root to: 'home#index'"

run "sed -i -e \"s/db\\/test.sqlite3/db\\/test<%= ENV[\\'TEST_ENV_NUMBER\\']%>.sqlite3/g\" config/database.yml"
run "cp config/database.yml config/database.yml.sample"

#generate 'scaffold', 'hoge', 'name:string', 'age:integer'
rake 'db:migrate'
#rake 'db:test:clone'
#rake 'spec'
#rake 'parallel:create'
rake 'parallel:prepare'
rake 'parallel:spec'