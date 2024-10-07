# frozen_string_literal: true

require "minitest/autorun"
require "mocha/minitest"
require_relative "../../../../lib/house_of_yaml/services/jira"

module HouseOfYaml
  module Services
    class JiraTest < Minitest::Test
      def setup
        @base_uri = "https://example.com/jira"
        @email = "test@example.com"
        @api_key = "test_api_key"
        @jira_service = Jira.new(base_uri: @base_uri,
                                 email: @email,
                                 api_key: @api_key)
      end

      def test_initialize_sets_base_uri_and_authentication
        assert_equal @base_uri, Jira.base_uri
        assert_equal @email, Jira.default_options[:basic_auth][:username]
        assert_equal @api_key, Jira.default_options[:basic_auth][:password]
        assert_equal "application/json", Jira.headers["Content-Type"]
      end

      def test_service_name_defaults_to_jira
        assert_equal "jira", @jira_service.service_name
      end

      def test_service_name_can_be_set
        @jira_service.service_name = "custom_jira"
        assert_equal "custom_jira", @jira_service.service_name
      end

      def test_fetch_data_returns_issues
        project_id = "project1"
        response_mock = mock
        response_mock.expects(:success?).returns(true)
        response_mock.expects(:body).returns({ "issues" => %w[issue1 issue2] }.to_json)
        Jira.expects(:get).with("/search", query: { jql: "project = #{project_id}" }).returns(response_mock)

        assert_equal %w[issue1 issue2], @jira_service.fetch_data(project_id)
      end

      def test_fetch_data_raises_error_on_failure
        project_id = "project1"
        response_mock = mock
        response_mock.expects(:success?).returns(false)
        response_mock.expects(:code).returns(500)
        Jira.expects(:get).with("/search", query: { jql: "project = #{project_id}" }).returns(response_mock)
        @jira_service.expects(:log_error)

        assert_raises(RuntimeError) { @jira_service.fetch_data(project_id) }
      end

      def test_transform_data_returns_yaml_data
        data = [
          {
            "id" => "issue1",
            "fields" => {
              "project" => { "id" => "project1" },
              "summary" => "Summary 1",
              "description" => "Description 1",
              "status" => { "name" => "Status 1" },
              "assignee" => { "displayName" => "Assignee 1" }
            }
          },
          {
            "id" => "issue2",
            "fields" => {
              "project" => { "id" => "project2" },
              "summary" => "Summary 2",
              "description" => "Description 2",
              "status" => { "name" => "Status 2" },
              "assignee" => { "displayName" => "Assignee 2" }
            }
          }
        ]

        expected_yaml_data = {
          "issue1" => {
            "id" => "issue1",
            "path" => "project1",
            "summary" => "Summary 1",
            "description" => "Description 1",
            "status" => "Status 1",
            "assignee" => "Assignee 1"
          },
          "issue2" => {
            "id" => "issue2",
            "path" => "project2",
            "summary" => "Summary 2",
            "description" => "Description 2",
            "status" => "Status 2",
            "assignee" => "Assignee 2"
          }
        }

        assert_equal expected_yaml_data, @jira_service.transform_data(data)
      end

      def test_fetch_projects_returns_projects
        response_mock = mock
        response_mock.expects(:success?).returns(true)
        response_mock.expects(:body).returns(%w[project1 project2].to_json)
        Jira.expects(:get).with("/project").returns(response_mock)

        assert_equal %w[project1 project2], @jira_service.fetch_projects
      end

      def test_fetch_projects_raises_error_on_failure
        response_mock = mock
        response_mock.expects(:success?).returns(false)
        response_mock.expects(:code).returns(500)
        Jira.expects(:get).with("/project").returns(response_mock)
        @jira_service.expects(:log_error)

        assert_raises(RuntimeError) { @jira_service.fetch_projects }
      end

      def test_each_output_yields_transformed_issues
        projects = [{ "id" => "project1" }, { "id" => "project2" }]
        issues = [
          {
            "id" => "issue1",
            "fields" => {
              "project" => { "id" => "project1" },
              "summary" => "Summary 1",
              "description" => "Description 1",
              "status" => { "name" => "Status 1" },
              "assignee" => { "displayName" => "Assignee 1" }
            }
          },
          {
            "id" => "issue2",
            "fields" => {
              "project" => { "id" => "project2" },
              "summary" => "Summary 2",
              "description" => "Description 2",
              "status" => { "name" => "Status 2" },
              "assignee" => { "displayName" => "Assignee 2" }
            }
          }
        ]
        @jira_service.expects(:fetch_projects).returns(projects)
        @jira_service.expects(:fetch_data).with("project1").returns([issues[0]])
        @jira_service.expects(:fetch_data).with("project2").returns([issues[1]])

        expected_output = [
          {
            "id" => "issue1",
            "path" => "project1",
            "summary" => "Summary 1",
            "description" => "Description 1",
            "status" => "Status 1",
            "assignee" => "Assignee 1"
          },
          {
            "id" => "issue2",
            "path" => "project2",
            "summary" => "Summary 2",
            "description" => "Description 2",
            "status" => "Status 2",
            "assignee" => "Assignee 2"
          }
        ]

        actual_output = []
        @jira_service.each_output do |output|
          actual_output << output
        end

        assert_equal expected_output, actual_output
      end
    end
  end
end
