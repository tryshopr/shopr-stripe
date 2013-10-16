module Shoppe
  module Stripe
    class Railtie < Rails::Engine
      
      initializer "shoppe.stripe.initializer" do
        Shoppe::Stripe.setup
        
        ActiveSupport.on_load(:action_view) do
          require 'shoppe/stripe/view_helpers'
          ActionView::Base.send :include, Shoppe::Stripe::ViewHelpers
        end
      end
      
    end
  end
end
