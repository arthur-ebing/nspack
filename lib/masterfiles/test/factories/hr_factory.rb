# frozen_string_literal: true

module MasterfilesApp
  module HRFactory # rubocop:disable Metrics/ModuleLength
    def create_employment_type(opts = {})
      id = get_available_factory_record(:employment_types, opts)
      return id unless id.nil?

      default = {
        employment_type_code: Faker::Lorem.unique.word
      }
      DB[:employment_types].insert(default.merge(opts))
    end

    def create_contract_type(opts = {})
      id = get_available_factory_record(:contract_types, opts)
      return id unless id.nil?

      default = {
        contract_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word
      }
      DB[:contract_types].insert(default.merge(opts))
    end

    def create_wage_level(opts = {})
      id = get_available_factory_record(:wage_levels, opts)
      return id unless id.nil?

      default = {
        wage_level: Faker::Number.decimal,
        description: Faker::Lorem.unique.word
      }
      DB[:wage_levels].insert(default.merge(opts))
    end

    def create_personnel_identifier(opts = {})
      id = get_available_factory_record(:personnel_identifiers, opts)
      return id unless id.nil?

      default = {
        hardware_type: Faker::Lorem.unique.word,
        identifier: Faker::Lorem.unique.word,
        in_use: false,
        available_from: '2010-01-01',
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:personnel_identifiers].insert(default.merge(opts))
    end

    def create_shift_type(opts = {})
      id = get_available_factory_record(:shift_types, opts)
      return id unless id.nil?

      plant_resource_id = create_plant_resource
      employment_type_id = create_employment_type

      default = {
        plant_resource_id: plant_resource_id,
        employment_type_id: employment_type_id,
        start_hour: Faker::Number.number(digits: 4),
        end_hour: Faker::Number.number(digits: 4),
        day_night_or_custom: Faker::Lorem.unique.word
      }
      DB[:shift_types].insert(default.merge(opts))
    end

    def create_contract_worker_packer_role(opts = {})
      id = get_available_factory_record(:contract_worker_packer_roles, opts)
      return id unless id.nil?

      default = {
        packer_role: Faker::Lorem.unique.word,
        default_role: false,
        part_of_group_incentive_target: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:contract_worker_packer_roles].insert(default.merge(opts))
    end

    def create_contract_worker(opts = {})
      id = get_available_factory_record(:contract_workers, opts)
      return id unless id.nil?

      employment_type_id = create_employment_type
      contract_type_id = create_contract_type
      wage_level_id = create_wage_level
      personnel_identifier_id = create_personnel_identifier
      shift_type_id = create_shift_type
      contract_worker_packer_role_id = create_contract_worker_packer_role
      default = {
        employment_type_id: employment_type_id,
        contract_type_id: contract_type_id,
        wage_level_id: wage_level_id,
        first_name: Faker::Lorem.unique.word,
        surname: Faker::Lorem.word,
        title: Faker::Lorem.word,
        email: Faker::Lorem.word,
        contact_number: Faker::Lorem.word,
        personnel_number: Faker::Lorem.unique.word,
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        active: true,
        personnel_identifier_id: personnel_identifier_id,
        shift_type_id: shift_type_id,
        packer_role_id: contract_worker_packer_role_id
      }
      DB[:contract_workers].insert(default.merge(opts))
    end

    def create_group_incentive(opts = {})
      id = get_available_factory_record(:group_incentives, opts)
      return id unless id.nil?

      system_resource_id = create_system_resource
      default = {
        system_resource_id: system_resource_id,
        contract_worker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        active: true,
        created_at: '2010-01-01 12:00',
        incentive_target_worker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        incentive_non_target_worker_ids: BaseRepo.new.array_for_db_col([1, 2, 3])
      }
      DB[:group_incentives].insert(default.merge(opts))
    end
  end
end
