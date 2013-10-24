require 'shoppe/stripe/version'
require 'shoppe/stripe/railtie'

module Shoppe
  module Stripe
    
    class << self
      
      def api_key
        Shoppe.settings.stripe_api_key
      end
      
      def publishable_key
        Shoppe.settings.stripe_publishable_key
      end
      
      def setup
        Shoppe.add_settings_group :stripe, [:stripe_api_key, :stripe_publishable_key, :stripe_currency]
        
        require 'stripe'

        require 'shoppe/stripe/order_extensions'
        Shoppe::Order.send :include, Shoppe::Stripe::OrderExtensions
        
        # When an order is confirmed, attempt to authorise the payment
        Shoppe::Order.before_confirmation do
          if self.properties['stripe_customer_token']
            begin
              charge = ::Stripe::Charge.create({:customer => self.properties['stripe_customer_token'], :amount => self.total_in_pence, :currency => Shoppe.settings.stripe_currency, :capture => false}, Shoppe.settings.stripe_api_key)
              self.paid_at = Time.now
              self.payment_method = 'Stripe'
              self.payment_reference = charge.id
            rescue ::Stripe::CardError
              raise Shoppe::Errors::PaymentDeclined, "Payment was declined by the payment processor."
            end
          end
        end
        
        # When an order is accepted, attempt to capture the payment
        Shoppe::Order.before_acceptance do
          if stripe_charge
            begin
              stripe_charge.capture
            rescue ::Stripe::Error
              raise Shoppe::Errors::PaymentDeclined, "Payment could not be captured by Stripe. Investigate with Stripe. Do not accept the order."
            end
          end
        end
        
        # When an order is rejected, attempt to refund the payment
        Shoppe::Order.before_rejection do
          if stripe_charge
            begin
              stripe_charge.refund
            rescue ::Stripe::Error
              raise Shoppe::Errors::PaymentDeclined, "Payment could not be captured by Stripe. Investigate with Stripe. Do not accept the order."
            end
          end
        end
      end
      
    end
  end
end
