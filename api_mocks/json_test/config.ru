# frozen_string_literal: true

require 'roda'
require 'net/http'

# rubocop:disable Metrics/BlockLength
# Log all calls from a JSON robot
class App < Roda
  plugin :symbolized_params
  plugin :json_parser

  route do |r|
    r.on 'messcada' do
      r.on 'robot' do
        r.on 'api' do
          response['Content-Type'] = 'application/json'
          puts "Received from #{request.ip}..."
          p params
          action_type = params.keys.first
          robot_params = params[action_type]
          mac_addr = params[action_type][:MAC]
          # ACTION_TYPES = %i[requestPing requestSetup requestDateTime publishStatus publishBarcodeScan publishButton publishLogon publishLogoff].freeze
          res = case action_type
                when 'requestPing'
                  { responsePong: robot_params }
                when 'requestDateTime'
                  { responseDateTime: { status: 'OK', MAC: mac_addr, date: Time.now.strftime('%Y-%m-%d'), time: Time.now.strftime('%H:%M:%S') } }
                when 'requestSetup'
                  { responseSetup: { MAC: mac_addr,
                                     status: 'OK',
                                     message: 'Setup...',
                                     name: 'Name here...',
                                     security: 'OPEN',
                                     date: Time.now.strftime('%Y-%m-%d'),
                                     time: Time.now.strftime('%H:%M:%S'),
                                     type: 'TERMINAL' } }
                else
                  {
                    responseUser: {
                      MAC: mac_addr,
                      LCD1: 'Response OK',
                      LCD2: '',
                      LCD3: '',
                      LCD4: '',
                      green: 'true',
                      orange: 'false',
                      red: 'false'
                    }
                  }
                end
          puts 'Responding with:'
          p res
          res.to_json
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

run App.freeze.app
