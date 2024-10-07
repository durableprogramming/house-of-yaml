require 'house_of_yaml'

HouseOfYaml::Services::Base.add 'asana'
asana_service = HouseOfYaml::Services::Base['asana']
asana_service.asana_api_key = 'your_asana_api_key'

HouseOfYaml.repo_path = '/path/to/your/repo'
HouseOfYaml.repo_url = 'https://github.com/your_username/your_repo.git' 
HouseOfYaml.sync
