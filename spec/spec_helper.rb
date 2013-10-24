# coding: utf-8
require 'rubygems'
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'
require 'capybara/rspec'
require 'webmock/rspec'
WebMock.allow_net_connect!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Devise
  # include Warden::Test::Helpers
  # config.include Devise::TestHelpers, type: :controller
  # config.include Devise::TestHelpers, type: :view
  config.include FeatureHelpers, type: :feature

  # ActiveDecorator
  config.include RSpec::Rails::DecoratorExampleGroup, type: :decorator, example_group: { file_path: config.escaped_path(%w[spec decorators])}
  config.include RSpec::Rails::DecoratorExampleGroup, type: :view, example_group: { file_path: config.escaped_path(%w[spec views])}

  config.before :each do
    # Devise
    # Warden.test_mode!
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :truncation
    end
    if example.metadata[:js]
      self.use_transactional_fixtures = false
    end
    DatabaseCleaner.start
  end

  config.after :each do
    # Devise
    # Warden.test_reset!
    DatabaseCleaner.clean
    if example.metadata[:js]
      self.use_transactional_fixtures = true
    end
  end

  Capybara.javascript_driver = :webkit
  Capybara.default_wait_time = 5
  Capybara.ignore_hidden_elements = true
  Capybara.asset_host = "http://localhost:3000"
end

shared_context "for rake task specs" do
  before do
    Rake.application = nil
    @rake = Rake.application
    @rake.init
    @rake.load_rakefile
  end
end