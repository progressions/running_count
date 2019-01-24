# frozen_string_literal: true

module RunningCount
  module Callbacks

    extend ActiveSupport::Concern

    def enqueue_count
      self.class.enqueue_change(self, self.class._counter_data)
    end

    def enqueue_sum
      aggregated_field = self.class._counter_data[:aggregated_field]

      return true unless self.previous_changes.has_key?(aggregated_field)

      diff = self.previous_changes[aggregated_field].last.to_i - self.previous_changes[aggregated_field].first.to_i

      if diff != 0
        self.class.enqueue_change(self, self.class._counter_data.merge(amount: diff))
      end
    end

    module ClassMethods

      def keep_running_count(relation, opts = {})
        destination_class = opts[:class_name] ? opts[:class_name].to_s.constantize : relation.to_s.camelcase.constantize

        if opts[:aggregated_field]
          self.after_commit :enqueue_sum, on: [:create, :update]
        else
          self.after_commit :enqueue_count, on: [:create, :update]
        end

        set_name = opts.fetch(:counter_column, "#{self.name.underscore.pluralize}_count")
        running_set_name = "running_#{set_name}"
        statement = "update_#{set_name}"

        # source_table is the table where the counted values are coming from
        # destination_table is the table where the counted values are being saved
        #
        count_statement_sql = %(
          PREPARE #{statement} (int) AS
          UPDATE "#{destination_class.table_name}" SET "#{set_name}" = (
            SELECT COUNT(*) FROM "#{self.table_name}"
            WHERE "#{self.table_name}"."#{relation}_id" = $1
          ) WHERE "#{destination_class.table_name}"."id" = $1
        )
        sum_statement_sql = %(
          PREPARE #{statement} (int) AS
          UPDATE "#{destination_class.table_name}" SET "#{set_name}" = (
            SELECT SUM(#{opts[:aggregated_field]}) FROM "#{self.table_name}"
            WHERE "#{self.table_name}"."#{relation}_id" = $1
          ) WHERE "#{destination_class.table_name}"."id" = $1
        )
        release_sql = %( DEALLOCATE #{statement} )

        @counter_data = {
          relation: relation,
          source: opts[:source],
          destination: self.table_name,
          set_name: set_name,
          running_set_name: running_set_name,
          statement: statement,
          release_sql: release_sql,
          aggregated_field: opts[:aggregated_field],
        }
        @counter_data[:statement_sql] = opts[:aggregated_field] ? sum_statement_sql : count_statement_sql

        klass = self

        destination_class.define_method(running_set_name) do
          self.send(set_name) + klass.running_count(self, running_set_name)
        end
      end

      def running_count(destination, running_set_name)
        item = Format.item(destination)

        Storage.scores(running_set_name, item).to_i
      end

      def _counter_data
        @counter_data
      end

      def enqueue_change(record, data)
        destination = record.send(data[:relation])
        item = Format.item(destination)

        Storage.add_item(item, data[:set_name], data[:running_set_name], data.fetch(:amount, 1))
      end

      def reconcile_changes
        prepare_statement

        begin
          members
            .each(&method(:reconcile_item))
        ensure
          release_statement
        end
      end

      def reconcile_item(item)
        Storage.clear_item(item, self._counter_data[:set_name], self._counter_data[:running_set_name])

        destination_id = Format.parse(item)
        ActiveRecord::Base.connection.exec_query("EXECUTE #{self._counter_data[:statement]}(#{destination_id})")
      end

      def prepare_statement
        ActiveRecord::Base.connection.exec_query(_counter_data[:statement_sql])
      end

      def release_statement
        ActiveRecord::Base.connection.exec_query(_counter_data[:release_sql])
      end

      def members(id = nil)
        Storage.members(self._counter_data[:set_name], id)
      end

      def scores
        Storage.scores(self.running_set_name)
      end

    end

  end
end
