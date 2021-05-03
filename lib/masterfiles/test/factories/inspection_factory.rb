# frozen_string_literal: true

module MasterfilesApp
  module InspectionFactory
    def create_inspection_type(opts = {}) # rubocop:disable Metrics/AbcSize
      inspection_failure_type_id = create_inspection_failure_type

      default = {
        inspection_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        inspection_failure_type_id: inspection_failure_type_id,
        applies_to_all_tms: false,
        applicable_tm_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        applies_to_all_tm_customers: false,
        applicable_tm_customer_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        applies_to_all_grades: false,
        applicable_grade_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        applies_to_all_marketing_org_party_roles: false,
        applicable_marketing_org_party_role_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        passed_default: false,
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
      inspector_party_role_id = create_party_role(party_type: 'P', name: AppConst::ROLE_INSPECTOR)

      default = {
        inspector_party_role_id: inspector_party_role_id,
        inspector_code: Faker::Lorem.unique.word,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: Faker::Number.number(digits: 4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspectors].insert(default.merge(opts))
    end
  end
end
