# frozen_string_literal: true

module RunningCount
  module Storage

    class << self

      def scores(running_set_name, item = nil)
        if item
          RunningCount.redis.zscore(running_set_name, item)
        else
          RunningCount.redis.zrange(running_set_name, 0, -1, with_scores: true)
        end
      end

      def add_item(item, running_set_name, amount)
        RunningCount.redis.zincrby(running_set_name, amount || 1, item)
      end

      def clear_item(item, running_set_name)
        RunningCount.redis.zrem(running_set_name, item)
      end

    end

  end
end
