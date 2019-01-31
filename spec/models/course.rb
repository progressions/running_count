class Course < ActiveRecord::Base
  belongs_to :user

  keep_running_count :user
end
