# frozen_string_literal: true

module ProductionApp
  module ResourceFactory
    def create_plant_resource(opts = {})
      plant_resource_type_id = create_plant_resource_type
      system_resource_id = create_system_resource

      default = {
        plant_resource_type_id: plant_resource_type_id,
        system_resource_id: system_resource_id,
        plant_resource_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        location_id: nil,
        resource_properties: nil,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:plant_resources].insert(default.merge(opts))
    end

    def create_plant_resource_type(opts = {})
      default = {
        plant_resource_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        icon: Faker::Lorem.word,
        packpoint: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:plant_resource_types].insert(default.merge(opts))
    end

    def create_system_resource(opts = {})
      system_resource_type_id = create_system_resource_type
      plant_resource_type_id = create_plant_resource_type

      default = {
        plant_resource_type_id: plant_resource_type_id,
        system_resource_type_id: system_resource_type_id,
        system_resource_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:system_resources].insert(default.merge(opts))
    end

    def create_system_resource_type(opts = {})
      default = {
        system_resource_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        computing_device: false,
        peripheral: false,
        icon: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:system_resource_types].insert(default.merge(opts))
    end
  end
end
