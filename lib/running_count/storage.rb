# frozen_string_literal: true

module RunningCount
  module Storage

    class << self

      def scores(running_set_name, item = nil)
        if item
          $redis.zscore(running_set_name, item)
        else
          $redis.zrange(running_set_name, 0, -1, with_scores: true)
        end
      end

      def add_item(item, running_set_name, amount)
        $redis.zincrby(running_set_name, amount || 1, item)
      end

      def clear_item(item, running_set_name)
        $redis.zrem(running_set_name, item)
      end

    end

  end
end
