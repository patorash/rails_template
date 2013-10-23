module RSpec::Rails
  module DecoratorExampleGroup
    extend ActiveSupport::Concern
    include RSpec::Rails::RailsExampleGroup
    include ActionView::TestCase::Behavior

    def decorate(obj)
      ActiveDecorator::Decorator.instance.decorate(obj)
      obj
    end

    included do
      metadata[:type] = :decorator

      before do
        ActiveDecorator::ViewContext.current = controller.view_context
      end
    end
  end
end