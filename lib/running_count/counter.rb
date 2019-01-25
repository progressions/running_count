# frozen_string_literal: true

module RunningCount
  module Counter

    class << self

      def enqueue_change(record, counter_data)
        destination = record.send(counter_data[:relation])
        item = Format.item(destination)

        Storage.add_item(item, counter_data[:running_set_name], counter_data.fetch(:amount, 1))
      end

      def reconcile_changes(counter_data)
        prepare_statement(counter_data)

        begin
          Storage
            .scores(counter_data[:running_set_name])
            .each { |item, _score| reconcile_item(item, counter_data) }
        ensure
          release_statement(counter_data)
        end
      end

      def reconcile_item(item, counter_data)
        Storage.clear_item(item, counter_data[:running_set_name])

        destination_id = Format.parse(item)
        ActiveRecord::Base.connection.exec_query("EXECUTE #{counter_data[:statement]}(#{destination_id})")
      end

      def prepare_statement(counter_data)
        ActiveRecord::Base.connection.exec_query(counter_data[:statement_sql])
      end

      def release_statement(counter_data)
        ActiveRecord::Base.connection.exec_query(counter_data[:release_sql])
      end

      def running_count(destination, running_set_name)
        item = Format.item(destination)

        Storage.scores(running_set_name, item).to_i
      end

    end

  end
end
