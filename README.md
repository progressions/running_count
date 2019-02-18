# running_count

Counter caches for Rails applications, including cached running counts.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'running_count', '~> 0.2`
```

And then execute:

    $ bundle

## Usage

```
class Course < ActiveRecord::Base
  belongs_to :user

  keep_running_count :user
end

class User
  has_many :courses
end
```

Tracks the number of Course records associated with the User model, saving them to the `courses_count` field in the 'users' table.

Also tracks a dynamic running count in the `running_courses_count` method on the `User` model.

## Reconciling changes

```
Course.reconcile_changes
```

Will update the 'users' table with the number of associated courses in the `courses_count` field, and clear the dynamic cache.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/progressions/running_count. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RunningCount project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/progressions/running_count/blob/master/CODE_OF_CONDUCT.md).
