module Shoppe
  module Stripe
    module ViewHelpers
      
      def shoppe_stripe_javascript
        String.new.tap do |s|
          s << javascript_include_tag('https://js.stripe.com/v2/')
          s << "<script type=\"text/javascript\">Stripe.setPublishableKey('#{Shoppe::Stripe.publishable_key}');</script>"
        end.html_safe
      end
      
    end
  end
end
