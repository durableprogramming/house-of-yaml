# House of YAML

<img src="/durableprogramming/house-of-yaml/raw/e34d216831602f92e64512ca09fc67889f321bb5/logo.svg" alt="logo" style="max-height: 150px;">

House of YAML is a powerful and flexible Ruby gem designed to simplify the process of synchronizing data from various services and storing it as human-readable YAML files in a Git repository. It provides a reliable and convenient way to backup, version control, and process your data, ensuring that it remains accessible and usable even if the original services change or become unavailable.

## Why Use House of YAML?

Vendor lockin is dangerous. Services and products are constantly evolving - or, depending on your perspective, devolving. Vendors may come and go, products can get discontinued, prices fluctuate, and pricing models shift. Relying solely on external services to store and manage your critical data can be risky. That's where House of YAML comes in.

House of YAML enables you to store your data as plain text in the YAML format. Plain text is a universal and timeless format that can be easily read, understood, and processed by humans and machines alike. By converting your data from proprietary formats or APIs into YAML, you ensure its longevity and accessibility, regardless of changes in the original services.

By storing your data in a Git repository, House of YAML provides the benefits of version control. You can track changes, revert to previous versions, and collaborate with others on your data. Git's distributed nature allows you to have multiple copies of your data repository, providing an additional layer of backup and redundancy.

YAML is a highly flexible and widely supported data serialization format. It can represent complex data structures, including nested objects and arrays, making it suitable for a wide range of data types. YAML files can be easily parsed and processed by various programming languages and tools, enabling seamless integration with your existing workflows and systems.

Regularly synchronizing your data from external services to YAML files in a Git repository acts as a reliable backup mechanism. In the event of service outages, data loss, or account termination, you can quickly restore your data from the YAML files. This provides peace of mind and ensures business continuity.

Having your data stored as plain text in YAML files opens up possibilities for data processing and analysis. You can easily write scripts or use existing tools to extract insights, perform transformations, or generate reports from your YAML data. Plain text files are portable and can be readily imported into various data analysis and visualization tools.

House of YAML is still in beta, and, for now, it only stores a subset of available data; still, that's enough to let you easily write integrations and write your own restore scripts if necessary.

## Getting Started

To start using House of YAML, simply install the gem in your Ruby project:

```
gem install house_of_yaml
```

Configure the gem with the necessary credentials and settings for the services you want to synchronize data from. House of YAML supports a few popular services out of the box - currently, JIRA and Asana - and provides a pluggable architecture for adding custom service integrations.


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

