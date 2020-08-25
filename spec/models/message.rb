# frozen_string_literal: true

class Message < ActiveRecord::Base

  has_many :receipts

end
