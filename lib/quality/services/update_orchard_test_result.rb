# frozen_string_literal: true

module QualityApp
  class UpdateOrchardTestResult < BaseService
    attr_reader :id, :orchard_test_type, :orchard_test_result, :api_attribute
    attr_accessor :params, :otmc_result, :attrs

    def initialize(id, params, user = nil)
      @id = id
      @orchard_test_result = repo.find_orchard_test_result_flat(id)
      @orchard_test_type = repo.find_orchard_test_type_flat(@orchard_test_result.orchard_test_type_id)
      @params = params.to_h
      @attrs = {}
      @api_attribute = @orchard_test_type.api_attribute&.to_sym
      @user = user
    end

    def call
      if orchard_test_type.result_type == AppConst::CLASSIFICATION
        classification_rules
      else
        pass_fail_rules
      end

      update_orchard_test_results

      success_response('Updated Tests')
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def classification_rules
      attrs[:passed] = !params[:api_result].nil_or_empty?
      attrs[:classification] = true
    end

    def pass_fail_rules
      pass_result = orchard_test_type.api_pass_result || ''
      attrs[:passed] = UtilityFunctions.parse_string_to_array(pass_result)&.map(&:upcase)&.include? params[:api_result]&.upcase
      attrs[:classification] = false
    end

    def update_orchard_test_results # rubocop:disable Metrics/AbcSize
      params[:group_ids] = repo.for_select_orchard_test_results(@orchard_test_result.orchard_test_type_id).map { |row| row[1] } if params[:update_all]
      params[:group_ids] = [id] if params[:group_ids].nil_or_empty?

      attrs[:freeze_result] = params[:freeze_result] || false
      attrs[:api_result] = params[:api_result]
      attrs[:api_result] = nil if attrs[:api_result].nil_or_empty?
      attrs[:applicable_from] = params[:applicable_from]
      attrs[:applicable_to] = params[:applicable_to]

      params[:group_ids].each do |group_id|
        next if repo.exists?(:orchard_test_results, attrs.merge(id: group_id))

        repo.update_orchard_test_result(group_id, attrs)
        repo.log_status(:orchard_test_results, group_id, 'UPDATED', user_name: @user&.user_name)
      end
    end
  end
end
