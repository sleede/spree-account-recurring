require 'stripe'
require 'stripe_tester' if Rails.env.development? || Rails.env.test?

Rails.application.config.assets.precompile += %w( spree/frontend/stripe.js )
