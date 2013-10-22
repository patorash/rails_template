# coding: utf-8
gem_group :development, :test do
  gem 'rspec-rails'
  gem 'capybara'
  gem 'capybara-webkit'
end

gem_group :development do
  gem 'pry-rails'
end

run 'bundle install'
generate 'rspec:install'
remove_dir 'test'

rake 'db:migrate'