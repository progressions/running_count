class Article < ActiveRecord::Base
  belongs_to :course

  keep_running_count(
    :course,
    counter_column: "published_article_count",
    if: proc { |model|
      model.try(:published?)
    },
    sql: ["articles.published = true"]
  )

end
