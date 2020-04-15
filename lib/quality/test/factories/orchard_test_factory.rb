# frozen_string_literal: true

module QualityApp
  module OrchardTestFactory
    def create_orchard_test_type(opts = {}) # rubocop:disable Metrics/AbcSize
      applicable_tm_group_ids = [create_target_market_group, create_target_market_group, create_target_market_group]
      applicable_cultivar_ids = [create_cultivar, create_cultivar, create_cultivar]
      applicable_commodity_group_ids = [create_commodity_group, create_commodity_group, create_commodity_group]

      default = {
        test_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        applies_to_all_markets: true,
        applies_to_all_cultivars: true,
        applies_to_orchard: false,
        allow_result_capturing: false,
        pallet_level_result: false,
        api_name: Faker::Lorem.word,
        result_type: Faker::Lorem.word,
        api_attribute: 'ABC',
        api_result_pass: 'ABC',
        applicable_tm_group_ids: BaseRepo.new.array_for_db_col(applicable_tm_group_ids),
        applicable_cultivar_ids: BaseRepo.new.array_for_db_col(applicable_cultivar_ids),
        applicable_commodity_group_ids: BaseRepo.new.array_for_db_col(applicable_commodity_group_ids),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:orchard_test_types].insert(default.merge(opts))
    end

    def create_orchard_test_result(opts = {})
      orchard_test_type_id = create_orchard_test_type
      orchard_id = create_orchard
      puc_id = create_puc
      cultivar_id = create_cultivar

      default = {
        orchard_test_type_id: orchard_test_type_id,
        puc_id: puc_id,
        orchard_id: orchard_id,
        cultivar_id: cultivar_id,
        passed: false,
        classification: false,
        freeze_result: false,
        api_result: nil,
        api_response: nil,
        applicable_from: '2010-01-01',
        applicable_to: '2010-01-01',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:orchard_test_results].insert(default.merge(opts))
    end
  end
end
