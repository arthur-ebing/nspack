# frozen_string_literal: true

module QualityApp
  class UpdateOrchardTestResult < BaseService
    attr_reader :id, :orchard_test_type, :orchard_test_result, :api_result, :result_attribute
    attr_accessor :params, :otmc_result

    def initialize(id, params)
      @id = id
      @params = params.to_h
      @api_result = @params.delete(:api_result) || {}
      @orchard_test_result = repo.find_orchard_test_result_flat(id)
      @orchard_test_type = repo.find_orchard_test_type_flat(@orchard_test_result.orchard_test_type_id)
      @result_attribute = @orchard_test_type.result_attribute&.to_sym
    end

    def call # rubocop:disable Metrics/AbcSize
      if orchard_test_type.result_type == AppConst::CLASSIFICATION
        classification_rules
      else
        pass_fail_rules
      end
      return success_response('No changes') if params == orchard_test_result.to_h.select { |key, _| params.keys.include?(key) }

      update_orchard_otmc_results unless result_attribute.nil?
      repo.update_orchard_test_result(id, params)
      success_response('Updated Orchard Test Result')
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def classification_rules
      params[:passed] = true
      params[:classification_only] = true
      @otmc_result = api_result[result_attribute]
    end

    def pass_fail_rules
      params[:passed] = AppConst::PHYT_CLEAN_PASSED.include? api_result[result_attribute]
      params[:classification_only] = false
      @otmc_result = params[:passed]
      update_pallet_sequences_otmc_results
    end

    def update_orchard_otmc_results
      otmc_results = repo.get(:orchards, params[:orchard_id], :otmc_results) || {}
      otmc_results[orchard_test_type.test_type_code.to_sym] = otmc_result
      repo.update(:orchards, params[:orchard_id], otmc_results: Sequel.hstore(otmc_results))
    end

    def update_pallet_sequences_otmc_results # rubocop:disable Metrics/AbcSize
      args = params.select { |key, _| %i[puc_id orchard_id cultivar_id].include?(key) }
      args[:packed_tm_group_id] = orchard_test_type.applicable_tm_group_ids unless orchard_test_type.applies_to_all_markets

      otmc_results = repo.select_values(:pallet_sequences,  %i[id failed_otmc_results], args) || []
      otmc_results.each do |id, otmc_result|
        otmc_result ||= []
        result = if params[:passed]
                   otmc_result - [orchard_test_type.test_type_code]
                 else
                   otmc_result + [orchard_test_type.test_type_code]
                 end
        next if result == otmc_result

        failed_otmc_results = result.empty? ? nil : repo.array_for_db_col(result.uniq)
        repo.update(:pallet_sequences, id, failed_otmc_results: failed_otmc_results)
      end
    end
  end
end
