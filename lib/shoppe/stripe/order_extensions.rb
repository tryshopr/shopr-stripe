module Shoppe
  module Stripe
    module OrderExtensions
      def accept_stripe_token(token)
        if token.start_with?('tok')
          customer = ::Stripe::Customer.create({ description: "Customer for order #{number}", card: token }, Shoppe::Stripe.api_key)
          properties['stripe_customer_token'] = customer.id
          save
        elsif token.start_with?('cus') && properties[:stripe_customer_token] != token
          properties['stripe_customer_token'] = token
          save
        elsif properties['stripe_customer_token'] && properties['stripe_customer_token'].start_with?('cus')
          true
        else
          false
        end
      end

      private

      def stripe_customer
        @stripe_customer ||= ::Stripe::Customer.retrieve(properties['stripe_customer_token'], Shoppe::Stripe.api_key)
      end

      def stripe_card
        @stripe_card ||= stripe_customer.cards.last
      end
    end
  end
end
