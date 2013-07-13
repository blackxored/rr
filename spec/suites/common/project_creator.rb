class ProjectCreator
  def initialize
    @mixins = []
    @configurators = []
    yield self if block_given?
  end

  def add(mixin)
    @mixins << mixin
  end

  def configure(&configurator)
    raise ArgumentError, "Block not given" unless configurator
    @configurators << configurator
  end

  def create(&block)
    mixins = @mixins
    configurators = @configurators

    project_class = Class.new(GenericProject) do
      mixins.each do |mixin|
        include mixin
      end

      define_method(:initialize) do |*args, &block|
        super(*args, &block)
        configurators.each do |configurator|
          puts "Got configurator: #{configurator.inspect}" if RR.debug?
          configurator.call(self)
        end
      end
    end

    project_class.create(&block)
  end
end
