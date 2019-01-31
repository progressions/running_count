require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'
require 'models/course'

require 'database_cleaner'
DatabaseCleaner.strategy = :deletion

describe "CounterCulture" do
  before(:each) do
    DatabaseCleaner.clean
  end

  it "increments counter cache on create" do
    Course.reconcile_changes
    user = User.create

    expect(user.courses_count).to eq(0)
    expect(user.running_courses_count).to eq(0)

    course = Course.create(user_id: user.id)

    expect(user.courses_count).to eq(0)
    expect(user.running_courses_count).to eq(1)

    Course.reconcile_changes

    user.reload

    expect(user.courses_count).to eq(1)
    expect(user.running_courses_count).to eq(1)
  end

end
