# frozen_string_literal: true

module RunningCount
  module Callbacks

    extend ActiveSupport::Concern

    def enqueue_count
      Counter.enqueue_change(self, self.class._counter_data)
    end

    def enqueue_sum
      aggregated_field = self.class._counter_data[:aggregated_field]

      return true unless self.previous_changes.has_key?(aggregated_field)

      diff = self.previous_changes[aggregated_field].last.to_i - self.previous_changes[aggregated_field].first.to_i

      if diff != 0
        Counter.enqueue_change(self, self.class._counter_data.merge(amount: diff))
      end
    end

    module ClassMethods

      def keep_running_count(relation, opts = {})
        destination_class = destination_class_name(relation, opts)

        add_callbacks(opts)

        counter_column = opts.fetch(:counter_column, "#{self.name.underscore.pluralize}_count")
        running_set_name = "running_#{counter_column}"
        statement = "update_#{counter_column}"

        sql = Statement.statement_sql(
          self,
          statement,
          destination_class,
          counter_column,
          relation,
          opts,
        )

        release_sql = %( DEALLOCATE #{statement} )

        @counter_data = {
          relation: relation,
          source: opts[:source],
          destination: self.table_name,
          running_set_name: running_set_name,
          statement: statement,
          release_sql: release_sql,
          aggregated_field: opts[:aggregated_field],
          statement_sql: sql,
          if: opts[:if],
        }

        destination_class.define_method(running_set_name) do
          self.send(counter_column) + Counter.running_count(self, running_set_name)
        end
      end

      def reconcile_changes
        Counter.reconcile_changes(self._counter_data)
      end

      def _counter_data
        @counter_data
      end

      private

      def add_callbacks(opts)
        if opts[:aggregated_field]
          self.after_commit :enqueue_sum, on: [:create, :update], if: opts[:if]
        else
          self.after_commit :enqueue_count, on: [:create, :update], if: opts[:if]
        end
      end

      def destination_class_name(relation, opts)
        opts[:class_name] ? opts[:class_name].to_s.constantize : relation.to_s.camelcase.constantize
      end

    end

  end
end
