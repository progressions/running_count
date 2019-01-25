# frozen_string_literal: true

module RunningCount
  module Statement

    class << self

      def statement_sql(klass, statement, destination_class, set_name, relation, opts)
        if opts[:aggregated_field]
          sum_statement_sql(klass, statement, destination_class, set_name, relation, opts)
        else
          count_statement_sql(klass, statement, destination_class, set_name, relation, opts)
        end
      end

      private

      def extra_sql(opts)
        if opts[:sql]
          opts[:sql].map { |sql| "AND #{sql}" }.join(" ")
        else
          nil
        end
      end

      def sum_inner_sql(klass, relation, opts)
        if opts[:scope]
          opts[:scope].call
        else
          %(
            SELECT SUM(#{opts[:aggregated_field]}) FROM "#{klass.table_name}"
            WHERE "#{klass.table_name}"."#{relation}_id" = $1
            #{extra_sql(opts)}
          )
        end
      end

      def count_inner_sql(klass, relation, opts)
        if opts[:scope]
          opts[:scope].call
        else
          %(
            SELECT COUNT(*) FROM "#{klass.table_name}"
            WHERE "#{klass.table_name}"."#{relation}_id" = $1
            #{extra_sql(opts)}
          )
        end
      end

      def sum_statement_sql(klass, statement, destination_class, set_name, relation, opts)
        inner_sql = sum_inner_sql(klass, relation, opts)

        %(
          PREPARE #{statement} (int) AS
          UPDATE "#{destination_class.table_name}" SET "#{set_name}" = (
            #{inner_sql}
          ) WHERE "#{destination_class.table_name}"."id" = $1
        )
      end

      def count_statement_sql(klass, statement, destination_class, set_name, relation, opts)
        inner_sql = count_inner_sql(klass, relation, opts)

        # source_table is the table where the counted values are coming from
        # destination_table is the table where the counted values are being saved
        #
        %(
          PREPARE #{statement} (int) AS
          UPDATE "#{destination_class.table_name}" SET "#{set_name}" = (
            #{inner_sql}
          ) WHERE "#{destination_class.table_name}"."id" = $1
        )
      end

    end

  end
end
