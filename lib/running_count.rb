# frozen_string_literal: true

require "running_count/callbacks"
require "running_count/counter"
require "running_count/statement"
require "running_count/format"
require "running_count/storage"

module RunningCount
  class Error < StandardError; end
end
