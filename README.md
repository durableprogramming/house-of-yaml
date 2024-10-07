# House Of Yaml

House Of Yaml is a Ruby gem that synchronizes data from various services and stores it as YAML files in a Git repository.

## Installation

Add this line to your application's Gemfile:

gem 'house_of_yaml'

And then execute:

$ bundle install

Or install it yourself as:

$ gem install house_of_yaml

## Usage

1. Configure the services you want to sync data from. Currently supported services are Asana and Jira.

HouseOfYaml::Services::Base.add('asana', asana_api_key: 'your_asana_api_key')
HouseOfYaml::Services::Base.add('jira', base_uri: 'https://your-jira-domain.atlassian.net', email: 'your_email', api_key: 'your_jira_api_key')

2. Specify the path to the local Git repository where the YAML files will be stored.

repo_path = '/path/to/your/repo'

3. Sync the data from the configured services.

HouseOfYaml.sync(repo_path)

4. Optionally, push the changes to the remote Git repository.

HouseOfYaml.push

## Supported Services

- Asana
- Jira

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/durableprogramming/house_of_yaml. 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

