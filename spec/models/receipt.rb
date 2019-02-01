class Receipt < ActiveRecord::Base
  belongs_to :message

  keep_running_count(
    :message,
    counter_column: "opened_message_count",
    if: proc { |model| model.opened_at }
  )
  keep_running_count(
    :message,
    counter_column: "sent_message_count",
    if: proc { |model| model.sent_at }
  )
end
