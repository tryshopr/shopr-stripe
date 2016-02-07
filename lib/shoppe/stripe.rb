require 'shoppe/stripe/version'
require 'shoppe/stripe/engine'

require 'shoppe/stripe/order_extensions'
require 'shoppe/stripe/payment_extensions'

module Shoppe
  module Stripe
    class << self
      def api_key
        ENV['STRIPE_API_KEY'] || Shoppe.settings.stripe_api_key
      end

      def publishable_key
        ENV['STRIPE_PUBLISHABLE_KEY'] || Shoppe.settings.stripe_publishable_key
      end

      def setup
        # Set the configuration which we would like
        Shoppe.add_settings_group :stripe, [:stripe_api_key, :stripe_publishable_key, :stripe_currency]

        # Require the external Stripe library
        require 'stripe'

        # When an order is confirmed, attempt to authorise the payment
        Shoppe::Order.before_confirmation do
          if properties['stripe_customer_token'] && total > 0.0
            begin
              charge = ::Stripe::Charge.create({ customer: properties['stripe_customer_token'], amount: (total * BigDecimal(100)).round, currency: Shoppe.settings.stripe_currency, capture: false }, Shoppe::Stripe.api_key)
              payments.create(amount: total, method: 'Stripe', reference: charge.id, refundable: true, confirmed: false)
            rescue ::Stripe::CardError
              raise Shoppe::Errors::PaymentDeclined, 'Payment was declined by the payment processor.'
            end
          end
        end

        # When an order is accepted, attempt to capture the payment
        Shoppe::Order.before_acceptance do
          payments.where(confirmed: false, method: 'Stripe').each do |payment|
            begin
              payment.stripe_charge.capture
              payment.update_attribute(:confirmed, true)
            rescue ::Stripe::CardError
              raise Shoppe::Errors::PaymentDeclined, "Payment ##{payment.id} could not be captured by Stripe. Investigate with Stripe. Do not accept the order."
            end
          end
        end

        # When an order is rejected, attempt to refund all the payments which have been
        # created with Stripe and are not confirmed.
        Shoppe::Order.before_rejection do
          payments.where(confirmed: false, method: 'Stripe').each do |payment|
            payment.refund!(payment.refundable_amount)
          end
        end

        # When a new payment is added which is a refund and associated with another Stripe method,
        # attempt to refund it automatically.
        Shoppe::Payment.before_create do
          if refund? && parent && parent.method == 'Stripe'
            begin
              options = {}
              if parent.confirmed?
                options[:amount] = (amount * BigDecimal(100)).round.abs
              else
                # If the original item hasn't been captured and the amount refunded isn't the
                # same as the orignal value, raise an error.
                if amount.abs != parent.refundable_amount
                  fail Shoppe::Errors::RefundFailed, message: "Refund could not be processed because charge hasn't been captured and the amount is not the same as the original payment."
                end
              end
              refund = parent.stripe_charge.refund(options)
              self.method = 'Stripe'
              self.reference = refund.id
              true
            rescue ::Stripe::CardError, ::Stripe::InvalidRequestError => e
              raise Shoppe::Errors::RefundFailed, message: "Refund could not be processed with Stripe (#{e.class}: #{e.message}). Please investigate with Stripe."
            end
          end
        end
      end
    end
  end
end
