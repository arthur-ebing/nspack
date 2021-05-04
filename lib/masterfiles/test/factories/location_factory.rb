# frozen_string_literal: true

module MasterfilesApp
  module LocationFactory
    def create_location(opts = {}) # rubocop:disable Metrics/AbcSize
      location_storage_type_id = create_location_storage_type(storage_type_code: opts.delete(:storage_type_code))
      location_type_id = create_location_type(location_type_code: opts.delete(:location_type_code))
      location_assignment_id = create_location_assignment(assignment_code: opts.delete(:assignment_code))
      location_storage_definition_id = create_location_storage_definition

      default = {
        primary_storage_type_id: location_storage_type_id,
        location_type_id: location_type_id,
        primary_assignment_id: location_assignment_id,
        location_long_code: Faker::Lorem.unique.word,
        location_description: Faker::Lorem.word,
        active: true,
        has_single_container: false,
        virtual_location: false,
        consumption_area: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        location_short_code: Faker::Lorem.unique.word,
        can_be_moved: false,
        print_code: Faker::Lorem.word,
        location_storage_definition_id: location_storage_definition_id,
        can_store_stock: false,
        units_in_location: Faker::Number.number(digits: 4)
      }
      DB[:locations].insert(default.merge(opts))
    end

    def create_location_storage_type(opts = {})
      opts[:storage_type_code] ||= Faker::Lorem.unique.word

      default = {
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        location_short_code_prefix: Faker::Lorem.word
      }
      DB[:location_storage_types].insert(default.merge(opts))
    end

    def create_location_type(opts = {})
      opts[:location_type_code] ||= Faker::Lorem.unique.word

      default = {
        short_code: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        can_be_moved: false,
        hierarchical: false
      }
      DB[:location_types].insert(default.merge(opts))
    end

    def create_location_assignment(opts = {})
      opts[:assignment_code] ||= Faker::Lorem.unique.word

      default = {
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:location_assignments].insert(default.merge(opts))
    end

    def create_location_storage_definition(opts = {})
      default = {
        storage_definition_code: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        storage_definition_format: Faker::Lorem.word,
        storage_definition_description: Faker::Lorem.word
      }
      DB[:location_storage_definitions].insert(default.merge(opts))
    end
  end
end
