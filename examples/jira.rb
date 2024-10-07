examples/jira.rb

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'house_of_yaml', path: '../'
end

require 'house_of_yaml'

HouseOfYaml.configure do |config|
  config.repo_url = 'https://github.com/your_username/your_repo.git'
  config.repo_path = './your_repo'
end

HouseOfYaml::Services::Base.add 'jira', 
    base_uri: 'https://your_jira_domain.atlassian.net/rest/api/2',
       email: 'your_email@example.com',
     api_key: 'your_jira_api_key'

HouseOfYaml.sync
