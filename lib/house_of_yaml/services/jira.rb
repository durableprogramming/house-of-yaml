# frozen_string_literal: true

require 'httparty'
require_relative "./base"

# The Jira service class interacts with the Jira API to fetch and transform data.
#
module HouseOfYaml
  module Services
    # Service class for interacting with Jira API
    class Jira < Base
      include HTTParty

      # Initializes a new instance of the Jira service
      #
      # @param base_uri [String] The base URI of the Jira API
      # @param email [String] The email used for authentication
      # @param api_key [String] The API key used for authentication
      def initialize(base_uri:, email:, api_key:)
        self.class.base_uri base_uri
        @email = email
        @api_key = api_key
        self.class.basic_auth @email, @api_key

        self.class.headers "Content-Type" => "application/json"
      end

      attr_writer :service_name

      # Returns the name of the service
      #
      # @return [String] The name of the service
      def service_name
        @service_name || "jira"
      end

      # Fetches data from Jira API for a given project ID
      #
      # @param project_id [String] The ID of the Jira project
      # @return [Array] The issues fetched from the Jira API
      def fetch_data(project_id)
        response = self.class.get("/search", query: { jql: "project = #{project_id}" })
        raise "Jira API request failed with status code #{response.code}" unless response.success?

        JSON.parse(response.body)["issues"]
      rescue StandardError => e
        log_error(e)
        raise "Failed to fetch Jira data: #{e.message}"
      end

      # Transforms Jira data into YAML format
      #
      # @param data [Array] The Jira data to transform
      # @return [Hash] The transformed data in YAML format
      def transform_data(data)
        yaml_data = {}
        data.each do |issue|
          fields = issue["fields"]
          key = issue["id"]
          yaml_data[key] = {
            "id" => issue["id"],
            "path" => fields.dig("project", "id"),
            "summary" => fields["summary"],
            "description" => fields["description"],
            "status" => fields.dig("status", "name"),
            "assignee" => fields.dig("assignee", "displayName")
          }
        rescue StandardError => e
          log_error(e)
          next
        end
        yaml_data
      end

      # Fetches all projects from Jira API
      #
      # @return [Array] The projects fetched from the Jira API
      def fetch_projects
        response = self.class.get("/project")
        raise "Jira API request failed with status code #{response.code}" unless response.success?

        JSON.parse(response.body)
      rescue StandardError => e
        log_error(e)
        raise "Failed to fetch Jira projects: #{e.message}"
      end

      # Yields each transformed issue from all Jira projects
      #
      # @yield [Hash] The transformed issue in YAML format
      def each_output
        projects = fetch_projects
        projects.each do |project|
          project_id = project["id"]
          data = fetch_data(project_id)
          data.each do |issue|
            transformed_issue = transform_data([issue])
            yield transformed_issue.values.first
          end
        end
      end

      private

      # Logs an error message and backtrace
      #
      # @param error [StandardError] The error to log
      def log_error(error)
        logger.error("Jira API Error: #{error.message}")
        logger.error(error.backtrace.join("\n"))
      end
    end
  end
end
