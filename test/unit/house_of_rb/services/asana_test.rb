# frozen_string_literal: true

require "minitest/autorun"
require "mocha/minitest"
require_relative "../../../../lib/house_of_yaml/services/asana"

module HouseOfYaml
  module Services
    class AsanaTest < Minitest::Test
      def setup
        @asana_api_key = "test_api_key"
        @asana_service = Asana.new(asana_api_key: @asana_api_key)
        @workspaces    = [{ "gid" => "workspace1" }, { "gid" => "workspace2" }]
        @projects      = [{ "gid" => "project1" }, { "gid" => "project2" }]
        @tasks         = [{ "gid" => "task1", "name" => "Task 1", "notes" => "Notes 1", "completed" => false, "assignee" => { "name" => "Assignee 1" } },
                          { "gid" => "task2", "name" => "Task 2", "notes" => "Notes 2", "completed" => true,
                            "assignee" => { "name" => "Assignee 2" } }]
      end

      def test_initialize_sets_base_uri_and_headers
        assert_equal "https://app.asana.com/api/1.0", Asana.base_uri
        assert_equal "Bearer #{@asana_api_key}", Asana.headers["Authorization"]
        assert_equal "application/json", Asana.headers["Content-Type"]
      end

      def test_service_name_defaults_to_asana
        assert_equal "asana", @asana_service.service_name
      end

      def test_service_name_can_be_set
        @asana_service.service_name = "custom_asana"
        assert_equal "custom_asana", @asana_service.service_name
      end

      def test_fetch_data_returns_tasks
        @asana_service.expects(:fetch_workspaces).returns(@workspaces)
        @asana_service.expects(:fetch_projects).with(@workspaces).returns(@projects)
        @asana_service.expects(:fetch_tasks).with(@projects).returns(@tasks)

        assert_equal @tasks, @asana_service.fetch_data
      end

      def test_fetch_data_raises_error_on_failure
        @asana_service.expects(:fetch_workspaces).raises(StandardError, "Fetch error")
        @asana_service.expects(:log_error)

        assert_raises(RuntimeError) { @asana_service.fetch_data }
      end

      def test_transform_data_returns_yaml_data
        expected_yaml_data = {
          "task1" => { "gid" => "task1", "path" => nil, "name" => "Task 1", "notes" => "Notes 1", "completed" => false,
                       "assignee" => "Assignee 1" },
          "task2" => { "gid" => "task2", "path" => nil, "name" => "Task 2", "notes" => "Notes 2", "completed" => true,
                       "assignee" => "Assignee 2" }
        }

        assert_equal expected_yaml_data, @asana_service.transform_data(@tasks)
      end

      def test_fetch_workspaces_returns_workspaces
        response_mock = mock
        response_mock.expects(:success?).returns(true)
        response_mock.expects(:body).returns({ "data" => @workspaces }.to_json)
        Asana.expects(:get).with("/workspaces").returns(response_mock)

        assert_equal @workspaces, @asana_service.fetch_workspaces
      end

      def test_fetch_workspaces_raises_error_on_failure
        response_mock = mock
        response_mock.expects(:success?).returns(false)
        response_mock.expects(:code).returns(500)
        Asana.expects(:get).with("/workspaces").returns(response_mock)

        assert_raises(RuntimeError) { @asana_service.fetch_workspaces }
      end

      def test_fetch_projects_returns_projects
        @workspaces.each do |workspace|
          response_mock = mock
          response_mock.expects(:success?).returns(true)
          response_mock.expects(:body).returns({ "data" => @projects }.to_json)
          Asana.expects(:get).with("/workspaces/#{workspace["gid"]}/projects").returns(response_mock)
        end

        assert_equal @projects * @workspaces.length, @asana_service.fetch_projects(@workspaces)
      end

      def test_fetch_projects_raises_error_on_failure
        response_mock = mock
        response_mock.expects(:success?).returns(false)
        response_mock.expects(:code).returns(500)
        Asana.expects(:get).with("/workspaces/#{@workspaces.first["gid"]}/projects").returns(response_mock)

        assert_raises(RuntimeError) { @asana_service.fetch_projects(@workspaces) }
      end

      def test_fetch_tasks_returns_tasks_with_project_path
        @projects.each do |project|
          response_mock = mock
          response_mock.expects(:success?).returns(true)
          response_mock.expects(:body).returns({ "data" => @tasks }.to_json)
          Asana.expects(:get).with("/projects/#{project["gid"]}/tasks").returns(response_mock)
        end

        expected_tasks = @projects.map do |pr|
          @tasks.map do |task|
            new_task = task.dup
            new_task["path"] = [pr["gid"]]
            new_task
          end
        end.flatten.sort_by { |_| [_["path"], _["gid"]] }

        out = @asana_service.fetch_tasks(@projects).sort_by { |_| [_["path"], _["gid"]] }

        assert_equal expected_tasks, out
      end

      def test_fetch_tasks_raises_error_on_failure
        response_mock = mock
        response_mock.expects(:success?).returns(false)
        response_mock.expects(:code).returns(500)
        Asana.expects(:get).with("/projects/#{@projects.first["gid"]}/tasks").returns(response_mock)

        assert_raises(RuntimeError) { @asana_service.fetch_tasks(@projects) }
      end

      def test_each_output_yields_tasks
        @asana_service.expects(:fetch_workspaces).returns(@workspaces).at_least_once
        @asana_service.expects(:fetch_projects).with(@workspaces).returns(@projects).at_least_once
        @asana_service.expects(:fetch_tasks).with(@projects.first).returns(@tasks).at_least_once
        @asana_service.expects(:fetch_tasks).with(@projects.last).returns(@tasks).at_least_once

        expected_output = @projects.map do |project|
          @tasks.map do |task|
            new_task = task.dup
            new_task["path"] = [project["gid"]]
            new_task
          end
        end.flatten.sort_by { |_| [_["path"], _["gid"]] }

        actual_output = []
        @asana_service.each_output do |output|
          actual_output << output
        end

        actual_output = actual_output.sort_by { |_| [_["path"], _["gid"]] }

        assert_equal expected_output, actual_output
      end
    end
  end
end
