# frozen_string_literal: true

module MasterfilesApp
  module RmtContainerFactory
    def create_rmt_container_material_owner(opts = {})
      id = get_available_factory_record(:rmt_container_material_owners, opts)
      return id unless id.nil?

      opts[:rmt_container_material_type_id] ||= create_rmt_container_material_type
      opts[:rmt_material_owner_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      DB[:rmt_container_material_owners].insert(opts)
    end

    def create_rmt_container_material_type(opts = {})
      id = get_available_factory_record(:rmt_container_material_types, opts)
      return id unless id.nil?

      opts[:rmt_container_type_id] ||= create_rmt_container_type
      default = {
        container_material_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        tare_weight: Faker::Number.decimal
      }
      DB[:rmt_container_material_types].insert(default.merge(opts))
    end

    def create_rmt_container_type(opts = {})
      id = get_available_factory_record(:rmt_container_types, opts)
      return id unless id.nil?

      default = {
        container_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        rmt_inner_container_type_id: nil,
        tare_weight: Faker::Number.decimal
      }
      DB[:rmt_container_types].insert(default.merge(opts))
    end
  end
end
