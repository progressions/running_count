class Message < ActiveRecord::Base
  has_many :receipts
end
