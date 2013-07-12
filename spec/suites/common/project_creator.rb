class ProjectCreator
  def initialize
    @mixins = []
    @configurators = []
  end

  def add(mixin)
    @mixins << mixin
  end

  def configure(&configurator)
    raise ArgumentError, "Block not given" unless configurator
    @configurators << configurator
  end

  def create
    mixins = @mixins
    configurators = @configurators

    project_class = Class.new(GenericProject) do
      mixins.each do |mixin|
        include mixin
      end

      define_method(:initialize) do |*args, &block|
        configurators.each do |configurator|
          configurator.call(self)
        end
        super(*args, &block)
      end
    end

    project_class.create
  end
end
