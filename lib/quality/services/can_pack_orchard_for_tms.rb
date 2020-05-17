# frozen_string_literal: true

module QualityApp
  class CanPackOrchardForTms < BaseService
    attr_reader :repo, :api, :season_id, :puc_id, :orchard_id, :cultivar_id, :tm_group_id

    def initialize(orchard_id:, cultivar_id:, tm_group_ids:)
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @puc_id = repo.get(:orchards, orchard_id, :puc_id)
      @orchard_id = orchard_id
      @cultivar_id = cultivar_id
      @tm_group_id = Array(tm_group_ids)
      raise ArgumentError, 'PhytClean Season not set.' if season_id.nil?

      orchard_cultivar_exists = repo.exists?(:orchards, Sequel.lit(" id = #{orchard_id} AND ARRAY[#{cultivar_id}] && cultivar_ids"))
      raise Crossbeams::InfoError, 'Cultivar not associated with Orchard.' unless orchard_cultivar_exists
    end

    def call
      return success_response('CanPackOrchardForTms Check bypassed') if AppConst::BYPASS_QUALITY_TEST_PRE_RUN_CHECK

      create_applicable_tests

      update_applicable_tests

      test_results
    end

    private

    def test_results
      failed_test_types = repo.failed_otmc_tests(orchard_id: orchard_id, cultivar_id: cultivar_id, tm_group_id: tm_group_id)
      return failed_response("Failed OTMC tests: #{failed_test_types.join(', ')}") unless failed_test_types.empty?

      ok_response
    end

    def update_applicable_tests
      service_res = QualityApp::PhytCleanStandardData.call(puc_id)
      raise Crossbeams::InfoError, service_res.message unless service_res.success

      ok_response
    end

    def create_applicable_tests
      repo.select_values(:orchard_test_types, :id).each do |orchard_test_type_id|
        args = { orchard_test_type_id: orchard_test_type_id, puc_id: puc_id, orchard_id: orchard_id, cultivar_id: cultivar_id }
        service_res = CreateOrchardTestResults.call(args)
        raise Crossbeams::InfoError, service_res.message unless service_res.success
      end

      ok_response
    end
  end
end
