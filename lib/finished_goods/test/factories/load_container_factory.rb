# frozen_string_literal: true

module FinishedGoodsApp
  module LoadContainerFactory
    def create_load_container(opts = {}) # rubocop:disable Metrics/AbcSize
      load_id = create_load
      cargo_temperature_id = create_cargo_temperature
      container_stack_type_id = create_container_stack_type

      default = {
        load_id: load_id,
        container_code: Faker::Lorem.unique.word,
        container_vents: Faker::Lorem.word,
        container_seal_code: Faker::Lorem.word,
        container_temperature_rhine: Faker::Number.decimal,
        container_temperature_rhine2: Faker::Number.decimal,
        internal_container_code: Faker::Lorem.unique.word,
        max_gross_weight: Faker::Number.decimal,
        tare_weight: Faker::Number.decimal,
        max_payload: Faker::Number.decimal,
        actual_payload: Faker::Number.decimal,
        verified_gross_weight: Faker::Number.decimal,
        verified_gross_weight_date: '2010-01-01 12:00',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        cargo_temperature_id: cargo_temperature_id,
        stack_type_id: container_stack_type_id
      }
      DB[:load_containers].insert(default.merge(opts))
    end

    def create_cargo_temperature(opts = {})
      default = {
        temperature_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        set_point_temperature: Faker::Number.decimal,
        load_temperature: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:cargo_temperatures].insert(default.merge(opts))
    end

    def create_container_stack_type(opts = {})
      default = {
        stack_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:container_stack_types].insert(default.merge(opts))
    end
  end
end
