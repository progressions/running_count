# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "rails_app/config/environment"

require "rspec"
require "running_count"

begin
  unless ENV["SHOW_MIGRATION_MESSAGES"]
    was = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
  end
  load "#{File.dirname(__FILE__)}/schema.rb"
ensure
  ActiveRecord::Migration.verbose = was unless ENV["SHOW_MIGRATION_MESSAGES"]
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = 1

RSpec.configure do |config|
  config.fail_fast = true # unless CI_TEST_RUN
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
end
