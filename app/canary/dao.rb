require 'concurrent/hash'
require 'faraday'
require 'mini_cache'
require 'net/http'
require 'openssl'

module CodeValet
  module Canary
    # The DAO module contains some data-access objects which are to be used
    # from the web tier.
    module DAO
      NET_ERRORS = [
        Timeout::Error,
        Errno::EINVAL,
        Errno::ECONNRESET,
        EOFError,
        Faraday::ConnectionFailed,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError,
        OpenSSL::SSL::SSLError,
      ].freeze

      # Access the caching object
      #
      # @returs [MiniCache::Store]
      def self.cache
        return @cache unless @cache.nil?

        @cache = MiniCache::Store.new
        @cache.instance_variable_set(:@data, Concurrent::Hash.new)
        return @cache
      end

      # Reset the cache, primarily intended for testing
      def self.clear_cache
        @cache = nil
      end
    end
  end
end
