# frozen_string_literal: true

require_relative "lib/house_of_yaml/version"

Gem::Specification.new do |spec|
  spec.name = "house-of-yaml"
  spec.version = HouseOfYaml::VERSION
  spec.authors = ["David J Berube"]
  spec.email = ["djberube@durableprogramming.com"]

  spec.summary = "Convert data from external services to YAML and store in Git"
  spec.description = "House::Of::Yaml is a Ruby gem that converts data from external services into YAML format and stores it in a local Git repository or on GitHub. It's primarily designed for ticketing systems like Asana and Jira but can be extended to work with other services through its plugin system."
  spec.homepage = "https://github.com/durableprogramming/house-of-yaml"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/durableprogramming/house-of-yaml"
  spec.metadata["changelog_uri"] = "https://github.com/durableprogramming/house-of-yaml/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.20.0"
  spec.add_dependency "zeitwerk", "~> 2.4"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "webmock", "~> 3.12"
  spec.add_dependency "git", "~> 1.11"
end
