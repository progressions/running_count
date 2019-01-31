# frozen_string_literal: true

module RunningCount
  module Callbacks

    extend ActiveSupport::Concern

    def enqueue_count
      Counter.enqueue_change(self, self.class._counter_data)
    end

    def enqueue_sum
      Counter.enqueue_sum(self, self.class._counter_data)
    end

    module ClassMethods

      def keep_running_count(relation, opts = {})
        Counter.add_callbacks(self, opts)

        @counter_data = Counter.counter_data(self.name, self.table_name, relation, opts)
      end

      def reconcile_changes
        Counter.reconcile_changes(self._counter_data)
      end

      def _counter_data
        @counter_data
      end

    end

  end
end
