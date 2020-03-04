# frozen_string_literal: true

module QualityApp
  class PhytCleanRequests < BaseService
    include PhytCleanCalls
    attr_accessor :responce, :api_result, :params

    def initialize
      @responce = []
      @api_result = {}
      @params = {}
    end

    def call
      res = request_citrus_eu_orchard_status
      return failed_response(res.message) unless res.success

      parse_response

      success_response(res.message)
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def request_citrus_eu_orchard_status # rubocop:disable Metrics/AbcSize
      res = auth_token_call
      return failed_response(res.message) unless res.success

      res = request_get_citrus_eu_orchard_status
      return failed_response(res.message) unless res.success

      message = 'Data cannot be retrieved as it is out of the valid querying period'
      return failed_response(message) if res.instance.first['notificationMessage'] == message

      @responce = res.instance
      save_to_yaml(@responce)
      success_response(res.message)
    end

    def parse_response
      pucs_list = repo.select_values(:pucs, :puc_code)
      responce.each do |hash|
        next unless pucs_list.include? hash['puc']

        @api_result = UtilityFunctions.symbolize_keys(hash)
        parse_record
      end
    end

    def parse_record # rubocop:disable Metrics/AbcSize
      puc_id = repo.get_with_args(:pucs, :id, puc_code: api_result[:puc])
      orchard_id = repo.get_with_args(:orchards, :id, orchard_code: api_result[:orch])
      cultivar_id = repo.get_with_args(:cultivars, :id, cultivar_code: api_result[:cultCode])
      @params = { puc_id: puc_id,
                  orchard_id: orchard_id }
      return unless params.all? { |_, v| !v.nil? }

      @params[:cultivar_id] = cultivar_id
      repo.update_pallet_sequences_phyto_data(api_result.merge(params))
      check_orchard_test_types
    end

    def check_orchard_test_types # rubocop:disable Metrics/AbcSize
      orchard_test_types = repo.select_values(:orchard_test_types, :id,  api_name: AppConst::PHYT_CLEAN)
      orchard_test_types.each do |id|
        params[:orchard_test_type_id] = id
        args = params.select { |key, _| %i[orchard_test_type_id puc_id orchard_id cultivar_id].include?(key) }

        orchard_test_result_id = repo.get_with_args(:orchard_test_results, :id, args) || repo.create_orchard_test_result(orchard_test_type_id: id)
        orchard_test_result = repo.find_orchard_test_result_flat(orchard_test_result_id)
        next if orchard_test_result.freeze_result

        params[:api_result] = api_result
        QualityApp::UpdateOrchardTestResult.call(orchard_test_result_id, params)
      end
    end

    def save_to_yaml(array)
      begin
        YAML.load_file('log/otmc_store.yml')
      rescue Errno::ENOENT
        File.open('log/otmc_store.yml', 'w') { |file| file.write([].to_yaml) }
      end

      File.open('log/otmc_store.yml', 'w') do |file|
        file.write(array.to_yaml)
      end
    end
  end
end
