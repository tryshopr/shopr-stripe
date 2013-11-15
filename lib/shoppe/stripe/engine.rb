module Shoppe
  module Stripe
    class Engine < Rails::Engine
      
      initializer "shoppe.stripe.initializer" do
        Shoppe::Stripe.setup
        ActiveSupport.on_load(:action_view) do
          require 'shoppe/stripe/view_helpers'
          ActionView::Base.send :include, Shoppe::Stripe::ViewHelpers
        end
      end
      
      config.to_prepare do
        Shoppe::Order.send :include, Shoppe::Stripe::OrderExtensions
        Shoppe::Payment.send :include, Shoppe::Stripe::PaymentExtensions
      end
      
    end
  end
end
