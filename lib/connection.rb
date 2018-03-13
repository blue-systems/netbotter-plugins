# frozen_string_literal: true
#
# Copyright (C) 2016 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) version 3, or any
# later version accepted by the membership of KDE e.V. (or its
# successor approved by the membership of KDE e.V.), which shall
# act as a proxy defined in Section 6 of version 3 of the license.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require 'faraday'
require 'json'
require 'uri'
require 'logger'

require(File.expand_path('representation', File.dirname(__FILE__)))

module Conduit
  # Connection logic wrapper.
  class Connection
    # FinerStruct wrapper around returned hash.
    class ConduitRepsonse < FinerStruct::Immutable
      def initialize(response)
        super(JSON.parse(response.body, symbolize_names: true))
      end

      def to_error
        RuntimeError.new("ConduitError #{error_code}: #{error_info}")
      end

      def error?
        !error_code.nil?
      end
    end

    class << self
      # Somewhat hackish since we have no global config.
      attr_accessor :api_token
    end

    attr_accessor :uri

    def initialize
      @uri = URI.parse('https://phabricator.kde.org/api')
    end

    def call(meth, kwords = {})
      response = get(meth, kwords)
      raise "HTTPError #{response.status}" if response.status != 200
      response = ConduitRepsonse.new(response)
      raise response.to_error if response.error?
      response.result
    end

    private

    def get(meth, kwords = {})
      client.get do |req|
        req.url meth
        req.headers['Content-Type'] = 'application/json'
        req.params = kwords.merge('api.token' => api_token)
      end
    end

    def api_token
      @api_token ||= ENV.fetch('PHABRICATOR_API_TOKEN', self.class.api_token)
    end

    def client
      @client ||= Faraday.new(@uri.to_s) do |faraday|
        faraday.request :url_encoded
        # faraday.response :logger, ::Logger.new(STDOUT), bodies: true
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
