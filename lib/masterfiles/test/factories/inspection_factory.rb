# frozen_string_literal: true

module MasterfilesApp
  module InspectionFactory
    def create_inspection_type(opts = {})
      inspection_failure_type_id = create_inspection_failure_type

      default = {
        inspection_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        inspection_failure_type_id: inspection_failure_type_id,
        applicable_tm_group_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        applicable_cultivar_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        applicable_orchard_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspection_types].insert(default.merge(opts))
    end

    def create_inspection_failure_type(opts = {})
      default = {
        failure_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspection_failure_types].insert(default.merge(opts))
    end

    def create_inspection_failure_reason(opts = {})
      inspection_failure_type_id = create_inspection_failure_type

      default = {
        inspection_failure_type_id: inspection_failure_type_id,
        failure_reason: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        main_factor: false,
        secondary_factor: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspection_failure_reasons].insert(default.merge(opts))
    end

    def create_inspector(opts = {})
      inspector_party_role_id = create_party_role('P', AppConst::ROLE_INSPECTOR)

      default = {
        inspector_party_role_id: inspector_party_role_id,
        inspector_code: Faker::Lorem.unique.word,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: Faker::Number.number(4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspectors].insert(default.merge(opts))
    end
  end
end
