# frozen_string_literal: true

module QualityApp
  class CreateOrchardTestResults < BaseService
    attr_reader :orchard_test_type, :ids

    def initialize(id = nil)
      @ids = Array(id || repo.select_values(:orchard_test_types, :id))
    end

    def call
      ids.each do |id|
        @orchard_test_type = repo.find_orchard_test_type_flat(id)
        delete_orchard_test_results

        create_orchard_test_results
      end

      success_response('Created Orchard Test Results')
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def delete_orchard_test_results # rubocop:disable Metrics/AbcSize
      current_result_ids = repo.select_values(:orchard_test_results, :id, orchard_test_type_id: orchard_test_type.id)
      valid_result_ids = repo.select_values(:orchard_test_results, :id, orchard_test_type_id: orchard_test_type.id, cultivar_id: Array(orchard_test_type.applicable_cultivar_ids))

      (current_result_ids - valid_result_ids).each do |id|
        repo.delete_orchard_test_result(id)
      end
    end

    def create_orchard_test_results # rubocop:disable Metrics/AbcSize
      pallet_groups = repo.select_values(:pallet_sequences, %i[puc_id orchard_id cultivar_id]).uniq
      bins_groups = repo.select_values(:rmt_bins, %i[puc_id orchard_id cultivar_id]).uniq
      groups = (pallet_groups + bins_groups).uniq

      groups.each do |puc_id, orchard_id, cultivar_id|
        attrs = { puc_id: puc_id, orchard_id: orchard_id, orchard_test_type_id: orchard_test_type.id }
        next unless Array(orchard_test_type.applicable_cultivar_ids).include? cultivar_id

        attrs[:cultivar_id] = cultivar_id
        next if repo.exists?(:orchard_test_results, attrs)

        attrs[:passed] = orchard_test_type.api_pass_result&.upcase == orchard_test_type.api_default_result&.upcase
        attrs[:api_result] = orchard_test_type.api_default_result

        if orchard_test_type.result_type == AppConst::CLASSIFICATION
          attrs[:passed] = !attrs[:api_result].nil_or_empty?
          attrs[:classification] = true
        end

        id = repo.create_orchard_test_result(attrs)
        repo.log_status(:orchard_test_results, id, 'CREATED')
      end
    end
  end
end
