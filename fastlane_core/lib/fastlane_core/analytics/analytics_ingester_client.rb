require 'faraday'
require 'json'
require 'openssl'

require_relative '../helper'

module FastlaneCore
  class AnalyticsIngesterClient
    def post_events(events)
      unless Helper.test?
        Thread.new do
          send_request(events)
        end
      end
      return true
    end

    def send_request(events, retries: 2)
      post_request(events)
    rescue
      retries -= 1
      retry if retries >= 0
    end

    def post_request(events)
      if ENV['METRICS_DEBUG']
        write_json(events.to_json)
      end
      url = "http://www.google-analytics.com"

      connection = Faraday.new(url) do |conn|
        conn.adapter(Faraday.default_adapter)
        if ENV['METRICS_DEBUG']
          conn.proxy = "https://127.0.0.1:8888"
          conn.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
        end
      end
      events.each do |event|
        connection.post do |req|
          req.url('/collect')
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            v: "1",                 # API Version
            tid: "UA-120900387-1",  # Tracking ID / Property ID
            cid: event.client_id,   # Client ID
            t: "event",             # Event hit type
            ec: event.category,     # Event category
            ea: event.action,       # Event action
            el: event.label,        # Event label
            ev: event.value         # Event value
          }
        end
      end
    end

    # This method is only for debugging purposes
    def write_json(body)
      File.write("#{ENV['HOME']}/Desktop/mock_analytics-#{Time.now.to_i}.json", body)
    end
  end
end
