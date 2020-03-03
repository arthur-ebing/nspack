# frozen_string_literal: true

module QualityApp
  class PhytCleanRequests < BaseService
    include PhytCleanCalls
    attr_accessor :responce, :hash, :params

    def initialize
      @responce = []
      @hash = {}
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
      success_response(res.message)
    end

    def parse_response
      pucs_list = repo.get_values(:pucs, :puc_code)
      responce.each do |hash|
        next unless pucs_list.include? hash['puc']

        @hash = UtilityFunctions.symbolize_keys(hash)
        parse_record
      end
    end

    def parse_record # rubocop:disable Metrics/AbcSize
      puc_id = repo.get_id(:pucs, puc_code: hash[:puc])
      orchard_id = repo.get_id(:orchards, orchard_code: hash[:orch])
      cultivar_id = repo.get_id(:cultivars, cultivar_code: hash[:cultCode])
      season = MasterfilesApp::CultivarRepo.new.find_cultivar_season(cultivar_id)

      @params = { puc_id: puc_id,
                  orchard_id: orchard_id,
                  cultivar_id: cultivar_id,
                  applicable_from: season&.start_date,
                  applicable_to: season&.end_date }

      repo.update_pallet_sequences_phyto_data(hash.merge(params))
      check_orchard_test_types
    end

    def check_orchard_test_types
      orchard_test_type_ids = repo.get_values(:orchard_test_types, :id,  api_name: AppConst::PHYT_CLEAN)
      orchard_test_type_ids.each do |id|
        result_attribute = repo.get(:orchard_test_type, id, :result_attributes).to_sym

        args = params.select { |key, _| %i[puc_id orchard_id cultivar_id].include?(key) }
        args[:orchard_test_type_id] = id

        orchard_test_result_id = repo.get_id(:orchard_test_results, args) || repo.create_orchard_test_result(orchard_test_type_id: id)
        orchard_test_result = repo.find_orchard_test_result_flat(orchard_test_result_id).to_h

        params[:passed] = AppConst::PHYT_CLEAN_PASSED.include? hash[result_attribute]
        current = orchard_test_result.select { |key, _| params.keys.include?(key) }
        next if params == current

        params[:api_result] = hash
        repo.update_orchard_test_result(orchard_test_result_id, params)
      end
    end
  end
end
# {
#   'puc': 'C2102',
#   'orch': '61',
#   'cultCode': 'NOV',
#   'cbs': 'true',
#   'applied': 'true',
#   'eu': 'TRUE',
#   'bd': 'NOT REQUIRED',
#   'verified': 'approved',
#   'fms': 'A1',
#   'b': 'false',
#   'updatedDT': '2019-08-05T12:24:00',
#   'serverDT': '2020-03-03T13:25:00',
#   'phytoData': 'EUA1A1FY  '
# }
