# frozen_string_literal: true

module QualityApp
  class UpdateOrchardTestResult < BaseService
    attr_reader :id, :orchard_test_type, :orchard_test_result, :api_result, :api_attribute
    attr_accessor :params, :otmc_result

    def initialize(id, params)
      @id = id
      @params = params.to_h
      @api_result = @params[:api_result]
      @orchard_test_result = repo.find_orchard_test_result_flat(id)
      @orchard_test_type = repo.find_orchard_test_type_flat(@orchard_test_result.orchard_test_type_id)
      @api_attribute = @orchard_test_type.api_attribute&.to_sym
    end

    def call
      if orchard_test_type.result_type == AppConst::CLASSIFICATION
        classification_rules
      else
        pass_fail_rules
      end

      update_orchard_test_results

      success_response('Updated Orchard Test Result')
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def classification_rules
      params[:passed] = true
      params[:classification] = true
    end

    def pass_fail_rules
      params[:passed] = orchard_test_type.api_result_pass == api_result
      params[:classification] = false
    end

    def update_orchard_test_results # rubocop:disable Metrics/AbcSize
      params[:group_ids] = repo.for_select_orchard_test_results(@orchard_test_result.orchard_test_type_id).map { |row| row[1] } if params[:update_all]
      params[:group_ids] = [id] if params[:group_ids].nil_or_empty?

      attrs = { passed: params[:passed],
                classification: params[:classification],
                freeze_result: params[:freeze_result] || false,
                api_result: params[:api_result],
                applicable_from: params[:applicable_from],
                applicable_to: params[:applicable_to] }

      params[:group_ids].each do |id|
        next if repo.exists?(:orchard_test_results, attrs.merge(id: id))

        repo.update_orchard_test_result(id, attrs)
      end
    end
  end
end
