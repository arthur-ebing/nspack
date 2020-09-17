# frozen_string_literal: true

module MasterfilesApp
  class StandardPackCodeContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:standard_pack_code).filled(Types::StrippedString)
      required(:material_mass).filled(:decimal)
      required(:plant_resource_button_indicator).maybe(Types::StrippedString)
      required(:description).maybe(Types::StrippedString)
      required(:std_pack_label_code).maybe(Types::StrippedString)
      required(:basic_pack_code_id).filled(:integer)
      required(:use_size_ref_for_edi).maybe(:bool)
      required(:palletizer_incentive_rate).filled(:decimal)
      required(:bin).filled(:bool)
      required(:rmt_container_type_id).maybe(:integer)
      required(:rmt_container_material_type_id).maybe(:integer)
    end

    rule(:rmt_container_type_id, :bin) do
      key.failure 'must be filled in' if values[:bin] && !values[:rmt_container_type_id]
    end

    rule(:rmt_container_material_type_id, :bin) do
      key.failure 'must be filled in' if values[:bin] && !values[:rmt_container_material_type_id]
    end
  end
end
