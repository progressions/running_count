require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'
require 'models/course'
require 'models/purchase'
require 'models/article'
require 'models/message'
require 'models/receipt'

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
    original_updated_at = user.updated_at.dup

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
    expect(user.updated_at).to be > original_updated_at
  end

  it "updates counter when a record is deleted" do
    Course.reconcile_changes

    user = User.create
    course = Course.create(user_id: user.id)
    original_updated_at = user.updated_at.dup

    Course.reconcile_changes

    user.reload

    expect(user.courses_count).to eq(1)
    expect(user.running_courses_count).to eq(1)
    expect(user.updated_at).to be > original_updated_at

    checkpoint_1_updated_at = user.updated_at.dup
    course.destroy
    user.reload

    expect(user.courses_count).to eq(1)
    expect(user.running_courses_count).to eq(0)
    expect(user.updated_at).to eq(checkpoint_1_updated_at)

    Course.reconcile_changes

    user.reload

    expect(user.courses_count).to eq(0)
    expect(user.running_courses_count).to eq(0)
    expect(user.updated_at).to be > checkpoint_1_updated_at
  end

  it "updates aggregated field on deletion" do
    Purchase.reconcile_changes

    user = User.create
    purchase = Purchase.create(user_id: user.id, net_charge_usd: 100)
    original_updated_at = user.updated_at.dup

    Purchase.reconcile_changes

    user.reload

    expect(user.transactions_gross).to eq(100)
    expect(user.running_transactions_gross).to eq(100)
    expect(user.updated_at).to be > original_updated_at

    checkpoint_1_updated_at = user.updated_at.dup
    purchase.destroy
    user.reload

    expect(user.transactions_gross).to eq(100)
    expect(user.running_transactions_gross).to eq(0)
    expect(user.updated_at).to eq(checkpoint_1_updated_at)

    Purchase.reconcile_changes

    user.reload

    expect(user.transactions_gross).to eq(0)
    expect(user.running_transactions_gross).to eq(0)
    expect(user.updated_at).to be > checkpoint_1_updated_at
  end

  it "aggregates field" do
    Purchase.reconcile_changes

    user = User.create
    original_updated_at = user.updated_at.dup

    expect(user.transactions_gross).to eq(0)
    expect(user.running_transactions_gross).to eq(0)

    count = 5
    count.times { Purchase.create(user_id: user.id, net_charge_usd: 100) }

    expect(user.transactions_gross).to eq(0)
    expect(user.running_transactions_gross).to eq(count * 100)
    expect(user.updated_at).to eq(original_updated_at)

    Purchase.reconcile_changes

    user.reload

    expect(user.transactions_gross).to eq(count * 100)
    expect(user.running_transactions_gross).to eq(count * 100)
    expect(user.updated_at).to be > original_updated_at
  end

  it "counts articles conditionally" do
    Article.reconcile_changes

    course = Course.create(user_id: user.id)
    original_updated_at = course.updated_at.dup

    expect(course.published_article_count).to eq(0)
    expect(course.running_published_article_count).to eq(0)

    article1 = Article.create(course_id: course.id, published: false)
    article2 = Article.create(course_id: course.id, published: true)

    expect(course.published_article_count).to eq(0)
    expect(course.running_published_article_count).to eq(1)
    expect(course.updated_at).to eq(original_updated_at)

    Article.reconcile_changes

    course.reload
    checkpoint_1_updated_at = course.updated_at.dup

    expect(course.published_article_count).to eq(1)
    expect(course.running_published_article_count).to eq(1)
    expect(course.updated_at).to be > original_updated_at

    article1.update!(published: true)

    expect(course.published_article_count).to eq(1)
    expect(course.running_published_article_count).to eq(2)
    expect(course.updated_at).to eq(checkpoint_1_updated_at)

    Article.reconcile_changes

    course.reload

    expect(course.published_article_count).to eq(2)
    expect(course.running_published_article_count).to eq(2)
    expect(course.updated_at).to be > checkpoint_1_updated_at
  end

  it "counts receipts to multiple columns" do
    Receipt.reconcile_changes

    message = Message.create
    original_updated_at = message.updated_at.dup

    expect(message.sent_message_count).to eq(0)
    expect(message.running_sent_message_count).to eq(0)

    expect(message.opened_message_count).to eq(0)
    expect(message.running_opened_message_count).to eq(0)

    receipt1 = Receipt.create(message_id: message.id, sent_at: Time.now)
    receipt2 = Receipt.create(message_id: message.id, sent_at: Time.now, opened_at: Time.now)

    expect(message.sent_message_count).to eq(0)
    expect(message.running_sent_message_count).to eq(2)

    expect(message.opened_message_count).to eq(0)
    expect(message.running_opened_message_count).to eq(1)

    expect(message.updated_at).to eq(original_updated_at)

    Receipt.reconcile_changes

    message.reload
    checkpoint_1_updated_at = message.updated_at.dup

    expect(message.sent_message_count).to eq(2)
    expect(message.running_sent_message_count).to eq(2)

    expect(message.opened_message_count).to eq(1)
    expect(message.running_opened_message_count).to eq(1)

    expect(message.updated_at).to be > original_updated_at

    receipt1.update!(opened_at: Time.now)

    expect(message.sent_message_count).to eq(2)
    expect(message.running_sent_message_count).to eq(2)

    expect(message.opened_message_count).to eq(1)
    expect(message.running_opened_message_count).to eq(2)

    expect(message.updated_at).to eq(checkpoint_1_updated_at)

    Receipt.reconcile_changes

    message.reload

    expect(message.sent_message_count).to eq(2)
    expect(message.running_sent_message_count).to eq(2)

    expect(message.opened_message_count).to eq(2)
    expect(message.running_opened_message_count).to eq(2)

    expect(message.updated_at).to be > checkpoint_1_updated_at
  end
end
