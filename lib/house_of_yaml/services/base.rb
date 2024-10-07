require "zeitwerk"
require "logger"

# The HouseOfYaml::Services::Base class serves as a base class for services.
# It provides class-level methods to manage and access registered services.
module HouseOfYaml
  module Services
    class Base
      class << self
        # Returns the array of registered services.
        def services
          @services ||= []
        end

        # Adds a new service to the registered services array.
        # The service can be specified by its name or class.
        # Additional keyword arguments can be passed to initialize the service.
        def add(service_name_or_class, **kwargs)
          service_class = if service_name_or_class.is_a?(String)
                            file_path = "#{__dir__}/#{service_name_or_class}"
                            Object.const_get("HouseOfYaml::Services::" + HouseOfYaml.loader.inflector.camelize(
                              service_name_or_class, file_path
                            ))
                          else
                            service_name_or_class
                          end

          services.push service_class.new(**kwargs)
        rescue NameError
          raise
        end

        # Retrieves a service by its name or index.
        # If a string or symbol is provided, it searches for a service with a matching service_name.
        # If an integer is provided, it returns the service at the specified index.
        def [](service_name_or_index)
          if service_name_or_index.is_a?(String) || service_name_or_index.is_a?(Symbol)
            services.select { |serv| serv.service_name == service_name_or_index.to_s }.first
          else
            services[service_name_or_index]
          end
        end
      end

      # Returns the logger instance for the service.
      # If no logger is set, it creates a new logger that outputs to $stdout.
      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end

