# frozen_string_literal: true

module MasterfilesApp
  RmtContainerMaterialTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rmt_container_type_id).filled(:integer)
    required(:container_material_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    optional(:party_role_ids).maybe(:array).each(:integer)
    optional(:tare_weight).maybe(:decimal)
  end
end
