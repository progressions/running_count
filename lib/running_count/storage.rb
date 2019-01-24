# frozen_string_literal: true

module RunningCount
  module Storage

    class << self

      def members(set_name, id = nil)
        if id.present?
          scan(set_name, id)
        else
          $redis.smembers(set_name)
        end
      end

      def scan(set, id)
        cursor = 0
        results = []

        loop do
          cursor, result = $redis.sscan(set, cursor, count: 1000, match: id)
          results += result

          break if cursor.to_i == 0
        end

        results
      end

      def scores(running_set_name, item = nil)
        if item
          $redis.zscore(running_set_name, item)
        else
          $redis.zrange(running_set_name, 0, -1, with_scores: true)
        end
      end

      def add_item(item, set_name, running_set_name, amount)
        $redis.multi do |multi|
          multi.sadd(set_name, item)
          multi.zincrby(running_set_name, amount || 1, item)
        end
      end

      def clear_item(item, set_name, running_set_name)
        $redis.multi do |multi|
          multi.srem(set_name, item)
          multi.zrem(running_set_name, item)
        end

      end
    end

  end
end
