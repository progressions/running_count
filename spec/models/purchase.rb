# frozen_string_literal: true

class Purchase < ActiveRecord::Base

  belongs_to :user

  keep_running_count :user, aggregated_field: :net_charge_usd, counter_column: :transactions_gross

end
