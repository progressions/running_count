require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'
require 'models/course'
require 'models/purchase'
require 'models/article'

require 'database_cleaner'
DatabaseCleaner.strategy = :deletion

describe RunningCount do
  let(:user) { User.create }

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

    user.reload

    expect(user.courses_count).to eq(count)
    expect(user.running_courses_count).to eq(count)
  end

  it "updates counter when a record is deleted" do
    Course.reconcile_changes

    user = User.create
    course = Course.create(user_id: user.id)

    Course.reconcile_changes

    user.reload

    expect(user.courses_count).to eq(1)
    expect(user.running_courses_count).to eq(1)

    course.destroy
    user.reload

    expect(user.courses_count).to eq(1)
    expect(user.running_courses_count).to eq(0)

    Course.reconcile_changes

    user.reload

    expect(user.courses_count).to eq(0)
    expect(user.running_courses_count).to eq(0)
  end

  it "updates aggregated field on deletion" do
    Purchase.reconcile_changes

    user = User.create
    purchase = Purchase.create(user_id: user.id, net_charge_usd: 100)

    Purchase.reconcile_changes

    user.reload

    expect(user.transactions_gross).to eq(100)
    expect(user.running_transactions_gross).to eq(100)

    purchase.destroy
    user.reload

    expect(user.transactions_gross).to eq(100)
    expect(user.running_transactions_gross).to eq(0)

    Purchase.reconcile_changes

    user.reload

    expect(user.transactions_gross).to eq(0)
    expect(user.running_transactions_gross).to eq(0)
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

    user.reload

    expect(user.transactions_gross).to eq(count * 100)
    expect(user.running_transactions_gross).to eq(count * 100)
  end

  it "counts articles conditionally" do
    Article.reconcile_changes

    course = Course.create(user_id: user.id)

    expect(course.published_article_count).to eq(0)
    expect(course.running_published_article_count).to eq(0)

    Article.create(course_id: course.id, published: false)
    Article.create(course_id: course.id, published: true)

    expect(course.published_article_count).to eq(0)
    expect(course.running_published_article_count).to eq(1)

    Article.reconcile_changes

    course.reload

    expect(course.published_article_count).to eq(1)
    expect(course.running_published_article_count).to eq(1)
  end
end
