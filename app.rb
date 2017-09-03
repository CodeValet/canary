#!/usr/bin/env ruby

require 'haml'
require 'raven'
require 'sinatra/base'
require 'sentry-api'

module CodeValet
  module Canary
    class App < Sinatra::Base
      enable  :sessions
      enable  :raise_errors
      disable :show_exceptions

      set :public_folder, File.dirname(__FILE__) + '/assets'

      SentryApi.configure do |config|
        config.endpoint = 'https://app.getsentry.com/api/0'
        config.auth_token = ENV['SENTRY_API_TOKEN']
        config.default_org_slug = 'codevalet'
      end

      get '/' do
        projects = []
        begin
          projects = SentryApi.projects
        rescue StandardError => exc
          Raven.capture_exception(exc)
        end

        haml :index,
              :layout => :_base,
              :locals => {
                  :projects => projects,
              }
      end

      get '/issue/:id' do
        issue = nil
        events = []
        begin
          issue = SentryApi.issue(params['id'])
          events = SentryApi.issue_events(params['id'])
        rescue StandardError => exc
          Raven.capture_exception(exc)
        end

        haml :issue,
              :layout => :_base,
              :locals => {
                  :issue => issue,
                  :events => events,
              }
      end
    end
  end
end
