# frozen_string_literal: true

module QualityApp
  class PhytCleanRequests < BaseService
    attr_accessor :response, :api_result, :params

    def initialize
      @response = []
      @api_result = {}
      @params = {}
    end

    def call # rubocop:disable Metrics/AbcSize
      res = api.auth_token_call
      return failed_response(res.message) unless res.success

      res = api.request_get_citrus_eu_orchard_status
      return failed_response(res.message) unless res.success

      message = 'Data cannot be retrieved as it is out of the valid querying period'
      return failed_response(message) if res.instance.first['notificationMessage'] == message

      save_to_yaml

      api.filter_phyt_clean_response(res.instance).each do |api_result|
        parse_record(api_result)
      end

      success_response(res.message)
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def api
      @api ||= PhytCleanApi.new
    end

    def parse_record(api_result) # rubocop:disable Metrics/AbcSize
      @api_result = api_result
      puc_id = repo.get_id(:pucs, puc_code: api_result[:puc])
      orchard_id = repo.get_id(:orchards, orchard_code: api_result[:orch], puc_id: puc_id)
      cultivar_id = repo.get_id(:cultivars, cultivar_code: api_result[:cultCode]) || repo.get_id(:cultivars, cultivar_name: api_result[:cultCode])

      @params = { puc_id: puc_id,
                  orchard_id: orchard_id,
                  cultivar_id: cultivar_id }
      return unless params.all? { |_, v| !v.nil? }

      check_orchard_test_types
    end

    def check_orchard_test_types # rubocop:disable Metrics/AbcSize
      orchard_test_types = repo.select_values(:orchard_test_types, :id,  api_name: AppConst::PHYT_CLEAN)
      orchard_test_types.each do |id|
        params[:orchard_test_type_id] = id
        args = params.select { |key, _| %i[orchard_test_type_id puc_id orchard_id cultivar_id].include?(key) }
        orchard_test_result_id = repo.get_id(:orchard_test_results, args)

        if orchard_test_result_id.nil?
          next unless repo.exists?(:pallet_sequences, params.select { |key, _| %i[puc_id orchard_id cultivar_id].include?(key) })

          orchard_test_result_id = repo.create_orchard_test_result(args)
        end

        orchard_test_result = repo.find_orchard_test_result_flat(orchard_test_result_id)
        next if orchard_test_result.freeze_result

        params[:api_result] = api_result
        QualityApp::UpdateOrchardTestResult.call(orchard_test_result_id, params)
      end
    end

    def save_to_yaml
      begin
        YAML.load_file('tmp/otmc_store.yml')
      rescue Errno::ENOENT
        File.open('tmp/otmc_store.yml', 'w') { |file| file.write([].to_yaml) }
      end

      File.open('tmp/otmc_store.yml', 'w') do |file|
        file.write(response.to_yaml)
      end
    end
  end
end
