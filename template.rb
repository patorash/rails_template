# coding: utf-8
gem 'slim-rails'
gem "simple_form", github: 'plataformatec/simple_form', branch: 'master'
gem "ransack"
gem 'whenever', require: false if yes?('Use whenever?')


use_bootstrap = if yes?('Use Bootstrap?')
                  uncomment_lines 'Gemfile', "gem 'therubyracer'"
                  gem 'less-rails'
                  gem 'twitter-bootstrap-rails'
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

append_to_file '.rspec' do
  '--format documentation'
  '--format ParallelTests::RSpec::FailuresLogger --out tmp/failing_specs.log'
end

generate 'controller', 'home index'
route "root to: 'home#index'"

run "sed -i -e \"s/db\\/test.sqlite3/db\\/test<%= ENV[\\'TEST_ENV_NUMBER\\']%>.sqlite3/g\" config/database.yml"
rake 'db:migrate'
#rake 'db:test:clone'
#rake 'spec'
#rake 'parallel:create'
rake 'parallel:prepare'
rake 'parallel:spec'