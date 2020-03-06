# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module LocationFactory
    def create_location(opts = {})
      location_storage_type_id = create_location_storage_type
      location_type_id = create_location_type
      location_assignment_id = create_location_assignment
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
        units_in_location: Faker::Number.number(4)
      }
      DB[:locations].insert(default.merge(opts))
    end

    def create_location_storage_type(opts = {})
      default = {
        storage_type_code: Faker::Lorem.unique.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        location_short_code_prefix: Faker::Lorem.word
      }
      DB[:location_storage_types].insert(default.merge(opts))
    end

    def create_location_type(opts = {})
      default = {
        location_type_code: Faker::Lorem.unique.word,
        short_code: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        can_be_moved: false,
        hierarchical: false
      }
      DB[:location_types].insert(default.merge(opts))
    end

    def create_location_assignment(opts = {})
      default = {
        assignment_code: Faker::Lorem.unique.word,
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
