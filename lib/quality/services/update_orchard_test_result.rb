# frozen_string_literal: true

module QualityApp
  class UpdateOrchardTestResult < BaseService
    attr_reader :id, :orchard_test_type, :orchard_test_result, :api_result, :result_attribute
    attr_accessor :params, :otmc_result

    def initialize(id, params)
      @id = id
      @params = params.to_h
      @api_result = @params[:api_result] || {}
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
      attrs = params
      attrs.delete(:api_result)
      return success_response('No changes') if attrs == orchard_test_result.to_h.select { |key, _| attrs.keys.include?(key) }

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
    end

    def update_orchard_otmc_results
      otmc_results = repo.get(:orchards, params[:orchard_id], :otmc_results) || {}
      otmc_results[orchard_test_type.test_type_code.to_sym] = otmc_result
      repo.update(:orchards, params[:orchard_id], otmc_results: Sequel.hstore(otmc_results))
    end
  end
end
