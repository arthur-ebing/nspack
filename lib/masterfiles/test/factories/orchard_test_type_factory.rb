# frozen_string_literal: true

module MasterfilesApp
  module OrchardTestTypeFactory
    def create_orchard_test_type(opts = {})
      default = {
        test_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        applies_to_all_markets: false,
        applies_to_all_cultivars: false,
        applies_to_orchard: false,
        applies_to_orchard_set: false,
        allow_result_capturing: false,
        pallet_level_result: false,
        api_name: Faker::Lorem.word,
        result_type: Faker::Lorem.word,
        result_attributes: 'ABC',
        applicable_tm_group_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        applicable_cultivar_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        applicable_commodity_group_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:orchard_test_types].insert(default.merge(opts))
    end
  end
end
