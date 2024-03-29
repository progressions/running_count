# frozen_string_literal: true

module RunningCount
  module Counter

    class << self

      def enqueue_changes(record, counter_data)
        counter_data
          .values
          .partition { |data| data[:aggregated_field].present? }
          .tap do |sums, counts|
            sums.each { |data| Counter.enqueue_sum(record, data) }
            counts.each { |data| Counter.enqueue_count(record, data) }
          end
      end

      def enqueue_sum(record, counter_data)
        aggregated_field = counter_data[:aggregated_field]

        return true unless record.previous_changes.has_key?(aggregated_field)

        diff = record.previous_changes[aggregated_field].last.to_i - record.previous_changes[aggregated_field].first.to_i

        if diff != 0
          Counter.enqueue_count(record, counter_data.merge(amount: diff))
        end
      end

      def enqueue_count(record, counter_data)
        if (changed_field = counter_data[:changed_field])
          return true unless record.previous_changes.has_key?(changed_field) && counter_data[:if].call(record)
        end

        destination = record.send(counter_data[:relation])
        item = Format.item(destination)

        Storage.add_item(item, counter_data[:running_set_name], counter_data.fetch(:amount, 1))
      end

      def enqueue_deletion(record, counter_data)
        counter_data.each_value do |data|
          Counter.enqueue_single_delete(record, data)
        end
      end

      def enqueue_single_delete(record, data)
        destination = record.send(data[:relation])
        item = Format.item(destination)
        amount = amount_from_deleted_record(record, data)

        Storage.add_item(item, data[:running_set_name], 0 - amount)
      rescue StandardError => exception
      end

      def reconcile_changes(counter_data)
        Statement.prepare_statement(counter_data)

        Storage
          .scores(counter_data[:running_set_name])
          .each { |item, _score| Statement.reconcile_item(item, counter_data) }
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

        destination_class.redefine_method(running_set_name) do
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
          counter_column: counter_column,
          relation: relation,
          source: opts[:source],
          destination: table_name,
          running_set_name: running_set_name,
          statement: statement,
          aggregated_field: opts[:aggregated_field],
          changed_field: opts[:changed_field],
          statement_sql: sql,
          if: opts[:if],
        }
      end

      def add_callbacks(klass, opts)
        klass.after_commit :enqueue_changes, on: [:create, :update], if: opts[:if]
        klass.after_commit :enqueue_deletion, on: [:destroy], if: opts[:if]
      end

      private

      def amount_from_deleted_record(record, counter_data)
        if counter_data[:aggregated_field]
          record.send(counter_data[:aggregated_field])
        else
          counter_data.fetch(:amount, 1)
        end
      end

      def destination_class_name(relation, opts)
        opts[:class_name] ? opts[:class_name].to_s.constantize : relation.to_s.camelcase.constantize
      end

    end

  end
end
