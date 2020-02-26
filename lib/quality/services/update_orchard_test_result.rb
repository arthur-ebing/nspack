# frozen_string_literal: true

module QualityApp
  class UpdateOrchardTestResult < BaseService
    attr_reader :id, :rule_object
    attr_accessor :params

    def initialize(id, params)
      @id = id
      @params = params.to_h
      @rule_object = repo.find_orchard_test_type_flat(@params[:orchard_test_type_id])
    end

    def call
      res = apply_orchard_test_rules
      return res unless res.success

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
      params[:passed] = true if rule_object.result_type == AppConst::CLASSIFICATION

      success_response('Rules applied.')
    end

    def update_orchard_test_result
      repo.update_orchard_test_result(id, params)

      instance = orchard_test_result
      success_response("Updated orchard test result #{instance.orchard_test_type_code}", instance)
    end
  end
end
