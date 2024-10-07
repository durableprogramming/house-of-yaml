# Service class for interacting with the Asana API
#
# This class provides methods for fetching and transforming data from the Asana API.
# It uses the HTTParty gem for making HTTP requests and inherits from a base service class.
#

require 'httparty'
require_relative 'base'

module HouseOfYaml
  module Services
    class Asana < Base
      include HTTParty

      # Initializes a new instance of the Asana service
      #
      # @param asana_api_key [String] The API key for authenticating with the Asana API
      def initialize(asana_api_key:)
        self.class.base_uri "https://app.asana.com/api/1.0"
        @api_key = asana_api_key
        self.class.headers "Authorization" => "Bearer #{@api_key}"
        self.class.headers "Content-Type" => "application/json"
      end

      attr_writer :service_name

      # Returns the name of the service
      #
      # @return [String] The name of the service (default: "asana")
      def service_name
        @service_name || "asana"
      end

      # Fetches data from the Asana API
      #
      # This method fetches workspaces, projects, and tasks from the Asana API.
      # It rescues any errors and raises a custom error message.
      #
      # @return [Array] An array of fetched tasks
      def fetch_data
        workspaces = fetch_workspaces
        projects = fetch_projects(workspaces)
        fetch_tasks(projects)
      rescue StandardError => e
        log_error(e)
        raise "Failed to fetch Asana data: #{e.message}"
      end

      # Transforms the fetched data into a YAML-compatible format
      #
      # @param data [Array] The fetched data to transform
      # @return [Hash] The transformed data as a hash
      def transform_data(data)
        yaml_data = {}
        data.flatten.each do |task|
          gid = task["gid"]
          yaml_data[gid] = {
            "gid" => task["gid"],
            "path" => task["path"],
            "name" => task["name"],
            "notes" => task["notes"],
            "completed" => task["completed"],
            "assignee" => task.dig("assignee", "name")
          }
        rescue StandardError => e
          log_error(e)
          next
        end
        yaml_data
      end

      # Fetches workspaces from the Asana API
      #
      # @return [Array] An array of fetched workspaces
      def fetch_workspaces
        response = self.class.get("/workspaces")
        raise "Asana API request failed with status code #{response.code}" unless response.success?

        JSON.parse(response.body)["data"]
      end

      # Fetches projects from the Asana API for the given workspaces
      #
      # @param workspaces [Array] An array of workspaces to fetch projects for
      # @return [Array] An array of fetched projects
      def fetch_projects(workspaces)
        projects = []
        workspaces.each do |workspace|
          response = self.class.get("/workspaces/#{workspace["gid"]}/projects")
          raise "Asana API request failed with status code #{response.code}" unless response.success?

          projects += JSON.parse(response.body)["data"]
        end
        projects
      end

      # Fetches tasks from the Asana API for the given projects
      #
      # @param projects [Array] An array of projects to fetch tasks for
      # @return [Array] An array of fetched tasks
      def fetch_tasks(projects)
        tasks = []
        projects.each do |project|
          response = self.class.get("/projects/#{project["gid"]}/tasks")

          raise "Asana API request failed with status code #{response.code}" unless response.success?

          rows = JSON.parse(response.body)["data"]
          rows = rows.map do |obj|
            new_obj = obj.dup
            new_obj["path"] = [project["gid"]]
            new_obj
          end

          tasks += rows
        end

        tasks.flatten
      end

      # Yields each task from the Asana API
      #
      # This method fetches workspaces, projects, and tasks from the Asana API and yields each task.
      # If workspaces and projects are provided, it uses those instead of fetching them.
      #
      # @param workspaces [Array] An optional array of workspaces to use (default: nil)
      # @param projects [Array] An optional array of projects to use (default: nil)
      # @yield [task] Yields each task
      def each_output(workspaces: nil, projects: nil)
        workspaces ||= fetch_workspaces
        projects   ||= fetch_projects(workspaces)

        projects.each do |pr|
          tasks = fetch_tasks(pr)

          tasks.each do |task|
            new_task = task.dup
            new_task["path"] = [pr["gid"]]
            yield new_task
          end
        end
      end

      private

      # Logs an error message and backtrace
      #
      # @param error [StandardError] The error to log
      def log_error(error)
        logger.error("Asana API Error: #{error.message}")
        logger.error(error.backtrace.join("\n"))
      end
    end
  end
end

