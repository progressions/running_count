# frozen_string_literal: true

module RunningCount
  module Format

    class << self

      def item(destination)
        JSON.generate(
          destination.id
        )
      end

      def parse(item)
        JSON.parse(item)
      end

    end

  end
end
