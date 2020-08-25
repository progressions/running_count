# frozen_string_literal: true

class Receipt < ActiveRecord::Base

  belongs_to :message

  keep_running_count(
    :message,
    counter_column: "opened_message_count",
    if: proc { |model| model.opened_at },
    sql: ["receipts.opened_at IS NOT NULL"],
    changed_field: :opened_at,
  )
  keep_running_count(
    :message,
    counter_column: "sent_message_count",
    if: proc { |model| model.sent_at },
    sql: ["receipts.sent_at IS NOT NULL"],
    changed_field: :sent_at,
  )

end
