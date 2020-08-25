# frozen_string_literal: true

require_relative "lib/running_count/version"

Gem::Specification.new do |spec|
  spec.name          = "running_count"
  spec.version       = RunningCount::VERSION
  spec.authors       = ["Isaac Priestley"]
  spec.email         = ["isaac@teachable.com"]

  spec.summary       = "Counter caches for Rails applications, including cached running counts."
  spec.description   = "Counter caches for Rails applications, including cached running counts. Using redis and native PostgreSQL features for performance gains"
  spec.homepage      = "https://github.com/UseFedora/running_count"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = "https://github.com/UseFedora/running_count"
  spec.metadata["changelog_uri"]     = "https://github.com/UseFedora/running_count"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "redis"
  spec.add_dependency "pg", ">= 0.20.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "database_cleaner"
end
