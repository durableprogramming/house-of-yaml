# frozen_string_literal: true

require "minitest/autorun"
require "mocha/minitest"
require_relative "../../../../lib/house_of_yaml/services/base"

module HouseOfYaml
  module Services
    class BaseTest < Minitest::Test
      def setup
        @base_service = Base.new
        Base.services.clear
      end

      def test_services_returns_empty_array_by_default
        assert_equal [], Base.services
      end

      def test_add_raises_argument_error_for_unsupported_service
        assert_raises(NameError) { Base.add("unsupported_service") }
      end

      def test_add_appends_new_service_instance_to_services_array
        service_class = mock("service_class")
        service_instance = mock("service_instance")
        service_class.expects(:new).returns(service_instance)

        Object.expects(:const_get).with("HouseOfYaml::Services::SupportedService").returns(service_class).at_least_once

        Base.add("supported_service")

        assert_includes Base.services, service_instance
      end

      def test_square_brackets_returns_service_by_name
        service1 = mock("service1")
        service1_instance = mock("service1_instance")
        service1_instance.expects(:service_name).returns("service1").at_least_once
        service1.expects(:new).returns(service1_instance)

        service2 = mock("service2")
        service2_instance = mock("service2_instance")
        service2_instance.expects(:service_name).returns("service2").at_least_once
        service2.expects(:new).returns(service2_instance)

        Base.add service1
        Base.add service2

        assert_equal service1_instance, Base["service1"]
        assert_equal service2_instance, Base["service2"]
      end

      def test_square_brackets_returns_service_by_index
        service1 = mock("service1")
        service2 = mock("service2")
        Base.services.replace([service1, service2])

        assert_equal service1, Base[0]
        assert_equal service2, Base[1]
      end

      def test_logger_returns_logger_instance
        assert_kind_of Logger, @base_service.logger
      end
    end
  end
end
