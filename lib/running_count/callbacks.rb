# frozen_string_literal: true

module RunningCount
  module Callbacks

    extend ActiveSupport::Concern

    def enqueue_changes
      self.class._counter_data.each do |counter_column, data|
        if data[:aggregated_field]
          Counter.enqueue_sum(self, data)
        else
          Counter.enqueue_change(self, data)
        end
      end
    end

    module ClassMethods

      def keep_running_count(relation, opts = {})
        data = Counter.counter_data(self.name, self.table_name, relation, opts)
        counter_column = data[:counter_column]

        @counter_data ||= {}
        @counter_data[counter_column] = data

        Counter.add_callbacks(self, opts)
      end

      def reconcile_changes
        self._counter_data.values.each do |data|
          Counter.reconcile_changes(data)
        end
      end

      def _counter_data
        @counter_data
      end

    end

  end
end
