module RR
  # RR::Space is a Dependency Injection http://en.wikipedia.org/wiki/Dependency_injection
  # and global state object for the RR framework. The RR::Space.instance
  # is a singleton that holds the state.
  class Space
    class << self
      def instance
        @instance ||= new
      end
      attr_writer :instance
      
      protected
      def method_missing(method_name, *args, &block)
        instance.__send__(method_name, *args, &block)
      end
    end

    attr_reader :doubles, :ordered_scenarios
    attr_accessor :trim_backtrace
    def initialize
      @doubles = HashWithObjectIdKey.new do |hash, subject_object|
        hash.set_with_object_id(subject_object, HashWithObjectIdKey.new)
      end
      @ordered_scenarios = []
      @trim_backtrace = false
    end

    # Creates a MockCreator.
    def mock_creator(subject, method_name=nil, &definition)
      setup_creator MockCreator, subject, method_name, definition
    end

    # Creates a StubCreator.
    def stub_creator(subject, method_name=nil, &definition)
      setup_creator StubCreator, subject, method_name, definition
    end

    # Creates a MockProbeCreator.
    def mock_probe_creator(subject, method_name=nil, &definition)
      setup_creator MockProbeCreator, subject, method_name, definition
    end

    # Creates a StubProbeCreator.
    def create_stub_probe_creator(subject, &definition)
      StubProbeCreator.new(self, subject, &definition)
    end

    # Creates a DoNotAllowCreator.
    def create_do_not_allow_creator(subject, &definition)
      DoNotAllowCreator.new(self, subject, &definition)
    end

    # Creates and registers a Scenario to be verified.
    def create_scenario(double)
      scenario = Scenario.new(self, double)
      double.register_scenario scenario
      scenario
    end

    # Reuses or creates, if none exists, a Double for the passed
    # in object and method_name.
    # When a Double is created, it binds the dispatcher to the
    # object.
    def create_double(object, method_name)
      double = @doubles[object][method_name.to_sym]
      return double if double

      double = Double.new(self, object, method_name.to_sym)
      @doubles[object][method_name.to_sym] = double
      double.bind
      double
    end

    # Registers the ordered Scenario to be verified.
    def register_ordered_scenario(scenario)
      @ordered_scenarios << scenario
    end

    # Verifies that the passed in ordered Scenario is being called
    # in the correct position.
    def verify_ordered_scenario(scenario)
      unless scenario.terminal?
        raise Errors::ScenarioOrderError,
              "Ordered Scenarios cannot have a NonTerminal TimesCalledExpectation"
      end
      unless @ordered_scenarios.first == scenario
        message = Scenario.formatted_name(scenario.method_name, scenario.expected_arguments)
        message << " called out of order in list\n"
        message << Scenario.list_message_part(@ordered_scenarios)
        raise Errors::ScenarioOrderError, message
      end
      @ordered_scenarios.shift unless scenario.attempt?
      scenario
    end

    # Verifies all the Double objects have met their
    # TimesCalledExpectations.
    def verify_doubles
      @doubles.each do |object, method_double_map|
        method_double_map.keys.each do |method_name|
          verify_double(object, method_name)
        end
      end
    end

    # Resets the registered Doubles and ordered Scenarios
    def reset
      reset_ordered_scenarios
      reset_doubles
    end

    # Verifies the Double for the passed in object and method_name.
    def verify_double(object, method_name)
      @doubles[object][method_name].verify
    ensure
      reset_double object, method_name
    end

    # Resets the Double for the passed in object and method_name.
    def reset_double(object, method_name)
      double = @doubles[object].delete(method_name)
      @doubles.delete(object) if @doubles[object].empty?
      double.reset
    end

    protected
    def setup_creator(klass, subject, method_name, definition)
      if method_name && definition
        raise ArgumentError, "Cannot pass in a method name and a block"
      end
      creator = klass.new(self, subject, &definition)
      return creator unless method_name
      creator.__send__(method_name)
    end
    
    # Removes the ordered Scenarios from the list
    def reset_ordered_scenarios
      @ordered_scenarios.clear
    end

    # Resets the registered Doubles for the next test run.
    def reset_doubles
      @doubles.each do |object, method_double_map|
        method_double_map.keys.each do |method_name|
          reset_double(object, method_name)
        end
      end
    end    
  end
end