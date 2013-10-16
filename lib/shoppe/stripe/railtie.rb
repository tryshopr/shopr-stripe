module Shoppe
  module Stripe
    class Railtie < Rails::Railtie
      
      initializer "shoppe.stripe.initializer" do
        Shoppe::Stripe.setup
      end
      
    end
  end
end
