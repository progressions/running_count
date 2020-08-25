# frozen_string_literal: true

require "active_support/concern"
require "active_support/lazy_load_hooks"
require "redis"

require "running_count/callbacks"
require "running_count/counter"
require "running_count/statement"
require "running_count/format"
require "running_count/storage"

module RunningCount

  class Error < StandardError; end

  class << self

    attr_accessor :redis

  end

end

# extend ActiveRecord with our own code here
ActiveSupport.on_load(:active_record) do
  include RunningCount::Callbacks
  RunningCount.redis ||= $redis # rubocop:disable Style/GlobalVars
  RunningCount.redis ||= REDIS if defined?(REDIS)
end
