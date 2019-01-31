require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'
require 'models/course'
require 'models/purchase'

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

    count = 10

    count.times do
      Course.create(user_id: user.id)
      print "."
    end

    expect(user.courses_count).to eq(0)
    expect(user.running_courses_count).to eq(count)

    bm = Benchmark.measure { Course.reconcile_changes }
    puts bm.inspect

    user.reload

    expect(user.courses_count).to eq(count)
    expect(user.running_courses_count).to eq(count)
  end

  it "aggregates field" do
    Purchase.reconcile_changes

    user = User.create

    expect(user.transactions_gross).to eq(0)
    expect(user.running_transactions_gross).to eq(0)

    count = 5

    count.times { Purchase.create(user_id: user.id, net_charge_usd: 100) }

    expect(user.transactions_gross).to eq(0)
    expect(user.running_transactions_gross).to eq(count * 100)

    Purchase.reconcile_changes
  end

end
