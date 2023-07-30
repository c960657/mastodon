# frozen_string_literal: true

Mime::Type.register 'application/json', :json, %w(text/x-json application/jsonrequest application/jrd+json application/activity+json application/ld+json)
Mime::Type.register 'text/xml',         :xml,  %w(application/xml application/atom+xml application/xrd+xml)

# Types not defined in Rack 2.2.
Rack::Mime::MIME_TYPES['.webp'] = 'image/webp'
Rack::Mime::MIME_TYPES['.avif'] = 'image/avif'
