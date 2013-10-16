module Shoppe
  module Stripe
    module OrderExtensions
      
      def accept_stripe_token(token)
        if token =~ /\Atok/
          customer = ::Stripe::Customer.create(:description => "Customer for order #{number}", :card => token)
          self.properties['stripe_customer_token'] = customer.id
          self.save
        elsif token =~ /\Acus/ && self.properties[:stripe_customer_token] != token
          self.properties['stripe_customer_token'] = token
          self.save
        elsif self.properties['stripe_customer_token'] && self.properties['stripe_customer_token'] =~ /\Acus/
          true
        else
          false
        end
      end
      
      private
      
      def stripe_customer
        @stripe_customer ||= ::Stripe::Customer.retrieve(self.properties['stripe_customer_token'])
      end
      
      def stripe_card
        @stripe_card ||= stripe_customer.cards.last
      end
      
      def stripe_charge
        return false unless self.paid? && self.payment_method == 'Stripe'
        @stripe_charge ||= ::Stripe::Charge.retrieve(self.payment_reference)
      end
      
    end
  end
end
