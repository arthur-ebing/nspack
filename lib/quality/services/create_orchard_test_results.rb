# frozen_string_literal: true

module QualityApp
  class CreateOrchardTestResults < BaseService
    attr_reader :orchard_test_type

    def initialize(id)
      @orchard_test_type = repo.find_orchard_test_type_flat(id)
    end

    def call
      create_orchard_test_results

      success_response('Created Orchard Test Results')
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def create_orchard_test_results # rubocop:disable Metrics/AbcSize
      repo.select_values(:orchards, %i[puc_id id cultivar_ids]).each do |puc_id, orchard_id, cultivar_ids|
        args = { puc_id: puc_id, orchard_id: orchard_id, orchard_test_type_id: orchard_test_type.id }
        cultivar_ids.each do |cultivar_id|
          next unless (Array(orchard_test_type.applicable_cultivar_ids).include? cultivar_id) || orchard_test_type.applies_to_all_cultivars

          args[:cultivar_id] = cultivar_id
          next if repo.exists?(:orchard_test_results, args)

          args[:passed] = orchard_test_type.api_pass_result&.upcase == orchard_test_type.api_default_result&.upcase
          args[:api_result] = orchard_test_type.api_pass_result

          if orchard_test_type.result_type == AppConst::CLASSIFICATION
            args[:classification] = true
            args[:passed] = true
          end

          id = repo.create_orchard_test_result(args)
          repo.log_status(:orchard_test_results, id, 'CREATED')
        end
      end
    end
  end
end
