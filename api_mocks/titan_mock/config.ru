# frozen_string_literal: true

require 'roda'

# rubocop:disable Metrics/BlockLength
# Mock calls for PPECB Ttan API
class App < Roda
  plugin :symbolized_params
  plugin :json_parser

  route do |r|
    @valid_token = 'aGoodToken'

    # GET / request
    r.root do
      <<~HTML
        This is a test app for mocking PPECB Titan calls
        - call using one of the required routes
      HTML
    end

    r.on 'APIAuth' do
      response['Content-Type'] = 'application/json'
      {
        token: @valid_token
      }.to_json
    end

    r.on 'pi' do
      r.on 'ProductInspection' do
        r.on 'consignment' do
          response['Content-Type'] = 'application/json'
          auth_token = request.fetch_header('HTTP_AUTHORIZATION')

          if auth_token == @valid_token
            {
              message: 'done'
            }.to_json
          else
            response.status = 401
            {
              message: 'Your token is no good here'
            }.to_json
          end
        rescue KeyError
          response.status = 401
          { message: 'No authentication supplied' }.to_json
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

run App.freeze.app
