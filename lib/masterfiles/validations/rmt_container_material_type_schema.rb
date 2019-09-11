# frozen_string_literal: true

module MasterfilesApp
  RmtContainerMaterialTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:rmt_container_type_id, :integer).filled(:int?)
    required(:container_material_type_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    optional(:party_role_ids, Types::IntArray)
    optional(:tare_weight, :decimal).maybe(:decimal?)
  end
end
