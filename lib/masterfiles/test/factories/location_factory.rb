# frozen_string_literal: true

module MasterfilesApp
  module LocationFactory
    def create_location(opts = {})
      id = get_available_factory_record(:locations, opts)
      return id unless id.nil?

      opts[:primary_storage_type_id] ||= create_location_storage_type(storage_type_code: opts.delete(:storage_type_code))
      opts[:location_type_id] ||= create_location_type(location_type_code: opts.delete(:location_type_code))
      opts[:primary_assignment_id] ||= create_location_assignment(assignment_code: opts.delete(:assignment_code))
      opts[:location_storage_definition_id] ||= create_location_storage_definition

      default = {
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
        can_store_stock: false,
        units_in_location: Faker::Number.number(digits: 4),
        maximum_units: Faker::Number.number(digits: 4)
      }
      DB[:locations].insert(default.merge(opts))
    end

    def create_location_storage_type(opts = {})
      id = get_available_factory_record(:location_storage_types, opts)
      return id unless id.nil?

      opts[:storage_type_code] ||= Faker::Lorem.unique.word
      default = {
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        location_short_code_prefix: Faker::Lorem.word
      }
      DB[:location_storage_types].insert(default.merge(opts))
    end

    def create_location_type(opts = {})
      id = get_available_factory_record(:location_types, opts)
      return id unless id.nil?

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
      id = get_available_factory_record(:location_assignments, opts)
      return id unless id.nil?

      opts[:assignment_code] ||= Faker::Lorem.unique.word
      default = {
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:location_assignments].insert(default.merge(opts))
    end

    def create_location_storage_definition(opts = {})
      id = get_available_factory_record(:location_storage_definitions, opts)
      return id unless id.nil?

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
