# frozen_string_literal: true

module MasterfilesApp
  StandardPackCodeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:standard_pack_code, Types::StrippedString).filled(:str?)
    required(:material_mass, :decimal).filled(:decimal?)
    required(:plant_resource_button_indicator, Types::StrippedString).maybe(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:std_pack_label_code, Types::StrippedString).maybe(:str?)
    required(:basic_pack_code_id, :integer).filled(:int?)
    required(:use_size_ref_for_edi, :bool).maybe(:bool?)
    required(:palletizer_incentive_rate, :decimal).filled(:decimal?)
    required(:bin, :bool).filled(:bool?)
    required(:rmt_container_type_id, :integer).maybe(:int?)
    required(:rmt_container_material_type_id, :integer).maybe(:int?)

    rule(rmt_container_type_id: %i[bin rmt_container_type_id]) { |bin, container_type| bin.true?.then(container_type.filled?) }
    rule(rmt_container_material_type_id: %i[bin rmt_container_material_type_id]) { |bin, material_type| bin.true?.then(material_type.filled?)  }
  end
end
