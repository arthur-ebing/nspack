# frozen_string_literal: true

module QualityApp
  class UpdateOrchardTestResult < BaseService
    attr_reader :id, :rule_object
    attr_accessor :params

    def initialize(id, params)
      @id = id
      @params = params.to_h

      @form_object = repo.find_orchard_test_result_flat(id)
      @rule_object = repo.find_orchard_test_type_flat(@form_object.orchard_test_type_id)
    end

    def call
      apply_orchard_test_rules

      update_orchard_test_result
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def orchard_test_result
      repo.find_orchard_test_result_flat(id)
    end

    def apply_orchard_test_rules
      if rule_object.result_type == AppConst::CLASSIFICATION
        classification_rules
      else
        pass_fail_rules
      end
    end

    def classification_rules
      params[:passed] = true
      params[:classification_only] = true
    end

    def pass_fail_rules
      params[:classification_only] = nil
    end

    def update_orchard_test_result
      repo.update_orchard_test_result(id, params)

      instance = orchard_test_result
      success_response("Updated orchard test result #{instance.orchard_test_type_code}", instance)
    end
  end
end
