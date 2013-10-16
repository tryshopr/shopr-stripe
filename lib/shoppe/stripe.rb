require 'shoppe/stripe/version'
require 'shoppe/stripe/railtie'

module Shoppe
  module Stripe
    
    class << self
      
      def api_key
        Shoppe.config['stripe']['api_key']
      end
      
      def publishable_key
        Shoppe.config['stripe']['publishable_key']
      end
      
      def setup
        require 'stripe'
        ::Stripe.api_key = self.api_key

        require 'shoppe/stripe/order_extensions'
        Shoppe::Order.send :include, Shoppe::Stripe::OrderExtensions
        
        # When an order is confirmed, attempt to authorise the payment
        Shoppe::Order.before_confirmation do
          if self.properties['stripe_customer_token']
            begin
              charge = ::Stripe::Charge.create(:customer => self.properties['stripe_customer_token'], :amount => self.total_in_pence, :currency => Shoppe.config['stripe']['currency'], :capture => false)
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
