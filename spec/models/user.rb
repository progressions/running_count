class User < ActiveRecord::Base
  has_many :courses
  has_many :purchases
end
