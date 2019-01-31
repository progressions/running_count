# frozen_string_literal: true

module RunningCount
  module Counter

    class << self

      def enqueue_sum(record, counter_data)
        aggregated_field = counter_data[:aggregated_field]

        return true unless record.previous_changes.has_key?(aggregated_field)

        diff = record.previous_changes[aggregated_field].last.to_i - record.previous_changes[aggregated_field].first.to_i

        if diff != 0
          Counter.enqueue_change(record, counter_data.merge(amount: diff))
        end
      end

      def enqueue_change(record, counter_data)
        destination = record.send(counter_data[:relation])
        item = Format.item(destination)

        Storage.add_item(item, counter_data[:running_set_name], counter_data.fetch(:amount, 1))
      end

      def reconcile_changes(counter_data)
        Statement.prepare_statement(counter_data)

        begin
          Storage
            .scores(counter_data[:running_set_name])
            .each { |item, _score| Statement.reconcile_item(item, counter_data) }
        ensure
          Statement.release_statement(counter_data)
        end
      end

      def running_count(destination, running_set_name)
        item = Format.item(destination)

        Storage.scores(running_set_name, item).to_i
      end

      def counter_data(name, table_name, relation, opts = {})
        destination_class = destination_class_name(relation, opts)

        counter_column = opts.fetch(:counter_column, "#{name.underscore.pluralize}_count")
        running_set_name = "running_#{counter_column}"
        statement = "update_#{counter_column}"

        destination_class.define_method(running_set_name) do
          self.send(counter_column) + Counter.running_count(self, running_set_name)
        end

        sql = Statement.statement_sql(
          table_name,
          statement,
          destination_class.table_name,
          counter_column,
          relation,
          opts,
        )

        {
          relation: relation,
          source: opts[:source],
          destination: table_name,
          running_set_name: running_set_name,
          statement: statement,
          release_sql: Statement.release_sql(statement),
          aggregated_field: opts[:aggregated_field],
          statement_sql: sql,
          if: opts[:if],
        }
      end

      def add_callbacks(klass, opts)
        if opts[:aggregated_field]
          klass.after_commit :enqueue_sum, on: [:create, :update], if: opts[:if]
        else
          klass.after_commit :enqueue_count, on: [:create, :update], if: opts[:if]
        end
      end

      private

      def destination_class_name(relation, opts)
        opts[:class_name] ? opts[:class_name].to_s.constantize : relation.to_s.camelcase.constantize
      end

    end

  end
end
