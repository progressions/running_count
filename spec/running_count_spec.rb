require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'
require 'models/course'
require 'models/purchase'
require 'models/article'

require 'database_cleaner'
DatabaseCleaner.strategy = :deletion

describe "CounterCulture" do
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

    count.times { Course.create(user_id: user.id) }

    expect(user.courses_count).to eq(0)
    expect(user.running_courses_count).to eq(count)

    Course.reconcile_changes

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
