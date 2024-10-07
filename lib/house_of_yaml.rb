# frozen_string_literal: true

require 'zeitwerk'
require 'git'

# House of YAML
#
# This module provides functionality to sync and manage YAML data from various services.
# It clones or pulls a repository, writes YAML files for each service's output data,
# commits the changes, and pushes the changes to the remote repository.
#
# The module uses the Zeitwerk library for autoloading and the Git gem for interacting
# with the Git repository.
#
module HouseOfYaml
  class << self
    attr_accessor :loader

    # Syncs data from various services by cloning or pulling the repository,
    # writing YAML files for each service's output data, and committing the changes.
    #
    # @param repo_path [String] The path to the repository.
    def sync(repo_path)
      @repo_path = repo_path

      Services::Base.services.each do |service|
        service.each_output do |output_data|
          yaml_data = { output_data["id"] => output_data }
          write_yaml_files(yaml_data, service.service_name)
        end
      rescue StandardError => e
        logger.error("Failed to sync data for service #{service.service_name}: #{e.message}\n#{e.backtrace.join("\n")}")
      end
      commit_changes
    end

    # Pushes the changes to the remote repository.
    def push
      Git.open(@repo_path).push
    rescue StandardError => e
      logger.error("Failed to push changes to remote: #{e.message}")
    end

    # Clones the repository if it doesn't exist, or pulls the latest changes if it does.
    def clone_or_pull_repo
      if Dir.exist?(@repo_path)
        Git.open(@repo_path).pull
      else
        Git.clone(@repo_url, @repo_path)
      end
    rescue StandardError => e
      logger.error("Failed to clone or pull repository: #{e.message}")
      raise
    end

    # Writes the YAML data to files in the repository.
    #
    # @param yaml_data [Hash] The YAML data to write.
    # @param service_name [String] The name of the service.
    def write_yaml_files(yaml_data, service_name)
      yaml_data.each do |key, data|
        file_path = File.join(@repo_path, service_name.to_s)
        if data.is_a?(Hash) && data.key?("path")
          path_parts = data["path"]
          file_path = File.join(file_path, *path_parts, "#{key}.yml")
        else
          file_path = File.join(file_path, "#{key}.yml")
        end
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, data.to_yaml)
      end
    end

    # Commits the changes to the repository.
    def commit_changes
      git = Git.open(@repo_path)
      git.add(all: true)
      git.commit("Update data from House::Of::Yaml")
    rescue StandardError => e
      logger.error("Failed to commit changes: #{e.message}")
    end

    # Returns the logger instance.
    #
    # @return [Logger] The logger instance.
    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end

loader = Zeitwerk::Loader.for_gem
HouseOfYaml.loader = loader
loader.setup

loader.eager_load
