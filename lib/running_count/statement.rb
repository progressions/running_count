# frozen_string_literal: true

module RunningCount
  module Statement

    class << self

      def statement_sql(table_name, statement, destination_table_name, set_name, relation, opts)
        basic_sql(
          statement,
          destination_table_name,
          set_name,
          inner_sql(table_name, relation, opts),
        )
      end

      def release_sql(name)
        %( DEALLOCATE #{name} )
      end

      def prepare_statement(counter_data)
        ActiveRecord::Base.connection.exec_query(counter_data[:statement_sql])
      rescue ActiveRecord::StatementInvalid
        Rails.logger.warn "Statement already exists: #{counter_data[:statement]}"
      end

      def release_statement(counter_data)
        ActiveRecord::Base.connection.exec_query(counter_data[:release_sql])
      end

      def reconcile_item(item, counter_data)
        Storage.clear_item(item, counter_data[:running_set_name])

        destination_id = Format.parse(item)
        ActiveRecord::Base.connection.exec_query("EXECUTE #{counter_data[:statement]}(#{destination_id})")
      end

      private

      def extra_sql(opts)
        if opts[:sql]
          opts[:sql].map { |sql| "AND #{sql}" }.join(" ")
        else
          nil
        end
      end

      def inner_sql(table_name, relation, opts)
        if opts[:scope]
          opts[:scope].call
        elsif opts[:aggregated_field]
          sum_inner_sql(table_name, relation, opts)
        else
          count_inner_sql(table_name, relation, opts)
        end
      end

      def sum_inner_sql(table_name, relation, opts)
        %(
          SELECT COALESCE(SUM(#{opts[:aggregated_field]}), 0) FROM "#{table_name}"
          WHERE "#{table_name}"."#{relation}_id" = $1
          #{extra_sql(opts)}
        )
      end

      def count_inner_sql(table_name, relation, opts)
        %(
          SELECT COUNT(*) FROM "#{table_name}"
          WHERE "#{table_name}"."#{relation}_id" = $1
          #{extra_sql(opts)}
        )
      end

      def sum_statement_sql(table_name, statement, destination_table_name, set_name, relation, opts)
        inner_sql = sum_inner_sql(table_name, relation, opts)

        basic_sql(statement, destination_table_name, set_name, inner_sql)
      end

      def count_statement_sql(table_name, statement, destination_table_name, set_name, relation, opts)
        inner_sql = count_inner_sql(table_name, relation, opts)

        basic_sql(statement, destination_table_name, set_name, inner_sql)
      end

      def basic_sql(statement, destination_table_name, set_name, inner_sql)
        # source_table is the table where the counted values are coming from
        # destination_table is the table where the counted values are being saved
        #
        %(
          PREPARE #{statement} (int) AS
          UPDATE "#{destination_table_name}" SET "#{set_name}" = (
            #{inner_sql}
          ) WHERE "#{destination_table_name}"."id" = $1
        )
      end

    end

  end
end
