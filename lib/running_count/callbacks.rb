# frozen_string_literal: true

module RunningCount
  module Callbacks

    extend ActiveSupport::Concern

    def enqueue_changes
      Counter.enqueue_changes(self, self.class._counter_data)
    end

    def enqueue_deletion
      Counter.enqueue_deletion(self, self.class._counter_data)
    end

    module ClassMethods

      def keep_running_count(relation, opts = {})
        data = Counter.counter_data(self.name, self.table_name, relation, opts)
        counter_column = data[:counter_column]

        _counter_data[counter_column] = data

        Counter.add_callbacks(self, opts)
      end

      def reconcile_changes
        self._counter_data.values.each do |data|
          Counter.reconcile_changes(data)
        end
      end

      def _counter_data
        @counter_data ||= {}
      end

    end

  end
end
