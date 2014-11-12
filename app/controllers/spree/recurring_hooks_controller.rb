module Spree
  class RecurringHooksController < BaseController
    skip_before_filter :verify_authenticity_token
    
    before_action :authenticate_webhook
    before_action :find_subscription

    respond_to :json

    def handler
      @subscription_event = @subscription.events.build(subscription_event_params)
      if @subscription_event.save
        render_status_ok
      else
        render_status_failure
      end
    end

    private

    def event
      @event ||= (Rails.env.production? ? params.deep_dup : params.deep_dup[:recurring_hook])
    end
    
    def authenticate_webhook
      render_status_ok if event.blank? || (event[:livemode] != Rails.env.production?) || (!Spree::Recurring::StripeRecurring::WEBHOOKS.include?(event[:type]))
    end

    def find_subscription
      if ['customer.subscription.deleted', 'customer.subscription.created', 'customer.subscription.updated'].include?(event[:type])
        @subscription = Spree::Subscription.find_by(stripe_subscription_id: event[:data][:object][:id])
      elsif ['invoice.created', 'invoice.payment_succeeded', 'invoice.payment_failed'].include?(event[:type])
        @subscription = Spree::Subscription.find_by(stripe_subscription_id: event[:data][:object][:subscription])
      end
      render_status_failure unless @subscription
    end

    def retrieve_api_event
      @event = @subscription.provider.retrieve_event(event[:id])
    end

    def subscription_event_params
      if retrieve_api_event && event.data.object.customer == @subscription.user.stripe_customer_id
        { event_id: event.id, request_type: event.type, response: event.to_json }
      else
        {}
      end
    end

    def render_status_ok
      render text: '', status: 200 and return
    end

    def render_status_failure
      render text: '', status: 403 and return
    end
  end
end
