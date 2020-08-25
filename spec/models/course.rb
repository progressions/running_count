# frozen_string_literal: true

class Course < ActiveRecord::Base

  belongs_to :user
  has_many :articles

  keep_running_count :user

end
