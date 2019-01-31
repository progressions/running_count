class User < ActiveRecord::Base
  has_many :courses

  keep_running_count :courses

end
