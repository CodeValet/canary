require 'faraday'
require 'canary/dao'
require 'raven'

module CodeValet::Canary::DAO
  # This DAO provides some basic caching calls through to Jenkins instances in
  # the Code Valet environment. The data it accesses is not "API" data per se
  # but rather information about the state of the instance.
  class Jenkins
    # Base URL to contrict
    URL_BASE = ENV['JENKINS_URL_BASE']
    CACHE_SECONDS = 300

    attr_reader :error

    def errored?
      return !@error.nil?
    end

    def rebuilt_alpha
      return cache.get_or_set('rebuiltAlpha', :expires_in => CACHE_SECONDS) do
        rebuilt_for('codevalet')
      end
    end

    def rebuilt_ga
      return cache.get_or_set('rebuiltGA', :expires_in => CACHE_SECONDS) do
        rebuilt_for('rtyler')
      end
    end

    # Method for directly querying a Jenkins instance to ask when it was last
    # rebuilt
    #
    # @return [String] response from the server if we reached it
    # @return [nil] nil on no response, #errored? should be set
    def rebuilt_for(user)
      # NOTE: worth investigating whether Jenkins will provide the appropriate
      # caching headers to
      url = "https://#{user}.codevalet.io/userContent/builtOn.txt"
      if URL_BASE
        url = "#{URL_BASE}/userContent/builtOn.txt"
      end

      response = connection.get(url)
      return response.body if response.success?

      @error = response.status
      return nil
    rescue *CodeValet::Canary::DAO::NET_ERRORS => e
      @error = e
      return nil
    rescue StandardError => e
      @error = e
      Raven.capture_exception(e)
      return nil
    end

    private

    def connection
      return Faraday.new(:ssl => { :verify => true }) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 4
        f.options.open_timeout = 3
      end
    end

    def cache
      return CodeValet::Canary::DAO.cache
    end
  end
end
