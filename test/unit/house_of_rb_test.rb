# frozen_string_literal: true

require "minitest/autorun"
require "mocha/minitest"
require_relative "../../lib/house_of_yaml"

module HouseOfYaml
  class HouseOfYamlTest < Minitest::Test
    def setup
      @repo_path = "/path/to/repo"
      @repo_url = "https://github.com/example/repo.git"
      HouseOfYaml.instance_variable_set(:@repo_path, @repo_path)
      HouseOfYaml.instance_variable_set(:@repo_url, @repo_url)
    end

    def test_sync_success
      service1 = mock("Service1")
      service2 = mock("Service2")
      Services::Base.stubs(:services).returns([service1, service2])

      service1.expects(:each_output).multiple_yields([{ "id" => 1 }], [{ "id" => 2 }])
      service1.expects(:service_name).returns("service1").at_least_once
      service2.expects(:each_output).multiple_yields([{ "id" => 3, "path" => %w[path to file] }], [{ "id" => 4 }])
      service2.expects(:service_name).returns("service2").at_least_once

      HouseOfYaml.expects(:write_yaml_files).with({ 1 => { "id" => 1 } }, "service1")
      HouseOfYaml.expects(:write_yaml_files).with({ 2 => { "id" => 2 } }, "service1")
      HouseOfYaml.expects(:write_yaml_files).with({ 3 => { "id" => 3, "path" => %w[path to file] } }, "service2")
      HouseOfYaml.expects(:write_yaml_files).with({ 4 => { "id" => 4 } }, "service2")
      HouseOfYaml.expects(:commit_changes)

      HouseOfYaml.sync(@repo_path)
    end

    def test_sync_error
      service = mock("Service")
      Services::Base.stubs(:services).returns([service])

      service.expects(:each_output).raises(StandardError, "Error")
      service.expects(:service_name).returns("service")

      HouseOfYaml.expects(:logger).returns(mock_logger).at_least_once
      mock_logger.expects(:error).at_least_once

      HouseOfYaml.sync(@repo_path)
    end

    def test_push_success
      git_mock = mock("Git")
      Git.expects(:open).with(@repo_path).returns(git_mock)
      git_mock.expects(:push)

      HouseOfYaml.push
    end

    def test_push_error
      Git.expects(:open).with(@repo_path).raises(StandardError, "Push error")

      HouseOfYaml.expects(:logger).returns(mock_logger)
      mock_logger.expects(:error).with("Failed to push changes to remote: Push error")

      HouseOfYaml.push
    end

    def test_clone_or_pull_repo_pull
      Dir.expects(:exist?).with(@repo_path).returns(true)
      git_mock = mock("Git")
      Git.expects(:open).with(@repo_path).returns(git_mock)
      git_mock.expects(:pull)

      HouseOfYaml.clone_or_pull_repo
    end

    def test_clone_or_pull_repo_clone
      Dir.expects(:exist?).with(@repo_path).returns(false)
      Git.expects(:clone).with(@repo_url, @repo_path)

      HouseOfYaml.clone_or_pull_repo
    end

    def test_clone_or_pull_repo_error
      Dir.expects(:exist?).with(@repo_path).returns(false)
      Git.expects(:clone).with(@repo_url, @repo_path).raises(StandardError, "Clone error")

      HouseOfYaml.expects(:logger).returns(mock_logger)
      mock_logger.expects(:error).with("Failed to clone or pull repository: Clone error")

      assert_raises(StandardError) { HouseOfYaml.clone_or_pull_repo }
    end

    def test_write_yaml_files_without_path
      yaml_data = { 1 => { "id" => 1 } }
      service_name = "service"

      file_path = File.join(@repo_path, service_name.to_s, "1.yml")
      FileUtils.expects(:mkdir_p).with(File.dirname(file_path))
      File.expects(:write).with(file_path, yaml_data[1].to_yaml)

      HouseOfYaml.write_yaml_files(yaml_data, service_name)
    end

    def test_write_yaml_files_with_path
      yaml_data = { 3 => { "id" => 3, "path" => %w[path to file] } }
      service_name = "service"

      file_path = File.join(@repo_path, service_name.to_s, "path", "to", "file", "3.yml")
      FileUtils.expects(:mkdir_p).with(File.dirname(file_path))
      File.expects(:write).with(file_path, yaml_data[3].to_yaml)

      HouseOfYaml.write_yaml_files(yaml_data, service_name)
    end

    def test_commit_changes_success
      git_mock = mock("Git")
      Git.expects(:open).with(@repo_path).returns(git_mock)
      git_mock.expects(:add).with(all: true)
      git_mock.expects(:commit).with("Update data from House::Of::Yaml")

      HouseOfYaml.commit_changes
    end

    def test_commit_changes_error
      Git.expects(:open).with(@repo_path).raises(StandardError, "Commit error")

      HouseOfYaml.expects(:logger).returns(mock_logger)
      mock_logger.expects(:error)

      HouseOfYaml.commit_changes
    end

    private

    def mock_logger
      @mock_logger ||= mock("Logger")
    end
  end
end
