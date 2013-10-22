# coding: utf-8
gem_group :development, :test do
  gem 'rspec-rails'
  gem "factory_girl_rails"
  gem 'capybara'
  gem 'capybara-webkit'
end

gem_group :development do
  gem 'pry-rails'
end

run 'bundle install'
generate 'rspec:install'
remove_dir 'test'

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

rake 'db:migrate'