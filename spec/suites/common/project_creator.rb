class ProjectCreator
  def initialize
    @projects = []
  end

  def add(mixin, &configurator)
    configurator ||= proc {}
    @projects << [mixin, configurator]
  end

  def create
    projects = @projects

    project_class = Class.new(GenericProject) do
      projects.each do |mixin, configurator|
        include mixin
      end

      define_method(:initialize) do |*args, &block|
        super(*args, &block)
        projects.each do |mixin, configurator|
          configurator.call(self)
        end
      end
    end

    project = project_class.new
    project.create
    project
  end
end
