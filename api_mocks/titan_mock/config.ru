# frozen_string_literal: true

require 'roda'
require 'yaml'
# rubocop:disable Metrics/BlockLength
# Mock calls for PPECB Titan API
class App < Roda
  plugin :symbolized_params
  plugin :json_parser

  # create some local storage to act as server for API
  begin
    YAML.load_file('titan_mock_store.yml')
  rescue Errno::ENOENT
    File.open('titan_mock_store.yml', 'w') { |file| file.write([].to_yaml) }
  end

  route do |r|
    @valid_token = 'aGoodToken'
    r.root do # GET / request
      <<~HTML
        This is a test app for mocking PPECB Titan calls
        - call using one of the required routes
      HTML
    end

    r.on 'oauth' do
      r.on 'ApiAuth' do
        response['Content-Type'] = 'application/json'
        credentials = JSON.parse(request.body.read)
        correct_credentials = { 'API_UserId' => '123456789', 'API_Secret' => 'some_secret' }
        if credentials.to_a == correct_credentials.to_a
          response.status = 200
          {
            succeeded: true,
            message: 'Login successful.',
            token: @valid_token,
            expiration: Time.now
          }.to_json
        else
          response.status = 401
          {
            succeeded: false,
            message: 'Login unsuccessful, Invalid credentials.'
          }.to_json
        end
      end
    end

    r.on 'pi' do
      r.on 'ProductInspection' do
        r.on 'InspectionResults' do
          response['Content-Type'] = 'application/json'
          titan_mock_store = YAML.load_file('titan_mock_store.yml')
          requested_inspection = titan_mock_store.detect { |hash| hash['consignmentNumber'] == params[:consignmentNumber] }
          consignment_lines = []
          requested_inspection['consignmentLines'].each do |line|
            consignment_lines << if [true, false].sample
                                   { sscc: line['sscc'],
                                     result: 'passed' }
                                 else
                                   { sscc: line['sscc'],
                                     result: 'rejected',
                                     rejectionReasons: [{ reason: 'CBS found',
                                                          reasonCode: 'CB01' }] }
                                 end
          end
          response.status = 200
          {
            consignment_number: requested_inspection['consignmentNumber'],
            upn: '111', # rand(10_000).to_s,
            inspectorCode: requested_inspection['inspectorCode'],
            inspector: requested_inspection['inspector'],
            consignmentLines: consignment_lines
          }.to_json
        end
      end
      r.on 'consignment' do
        response['Content-Type'] = 'application/json'
        auth_token = request.fetch_header('HTTP_HTTP_AUTHORIZATION')

        if auth_token == @valid_token
          titan_mock_store = YAML.safe_load(File.read('titan_mock_store.yml'))
          titan_mock_store << JSON.parse(request.body.read)
          File.open('titan_mock_store.yml', 'w') do |file|
            file.write((titan_mock_store.reverse.uniq { |instance| [instance[:consignmentNumber]] }).to_yaml)
          end

          response.status = 200
          {
            message: 'Inspection message received successfully.',
            inspectionMessageId: 1
          }.to_json
        else
          response.status = 401
          { message: 'Invalid token.' }.to_json
        end
      rescue KeyError
        response.status = 401
        { message: 'No authentication supplied' }.to_json
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
run App.freeze.app
