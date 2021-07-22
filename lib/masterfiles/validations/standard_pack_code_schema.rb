# frozen_string_literal: true

module MasterfilesApp
  class StandardPackContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:standard_pack_code).filled(Types::StrippedString)
      required(:material_mass).filled(:decimal)
      required(:plant_resource_button_indicator).maybe(Types::StrippedString)
      required(:description).maybe(Types::StrippedString)
      required(:std_pack_label_code).maybe(Types::StrippedString)
      required(:use_size_ref_for_edi).maybe(:bool)
      required(:palletizer_incentive_rate).filled(:decimal)
      required(:bin).filled(:bool)
      required(:rmt_container_material_owner_id).maybe(:integer)
      optional(:basic_pack_ids).maybe(:array).maybe { each(:integer) }
    end
  end
end
