# frozen_string_literal: true

module MasterfilesApp
  module HRFactory
    def create_employment_type(opts = {})
      default = {
        employment_type_code: Faker::Lorem.unique.word
      }
      DB[:employment_types].insert(default.merge(opts))
    end

    def create_contract_type(opts = {})
      default = {
        contract_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word
      }
      DB[:contract_types].insert(default.merge(opts))
    end

    def create_wage_level(opts = {})
      default = {
        wage_level: Faker::Number.decimal,
        description: Faker::Lorem.unique.word
      }
      DB[:wage_levels].insert(default.merge(opts))
    end

    def create_personnel_identifier(opts = {})
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

    def create_contract_worker(opts = {}) # rubocop:disable Metrics/AbcSize
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
  end
end
