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
    optional(:basic_pack_code_id, :integer).filled(:int?)
    required(:use_size_ref_for_edi, :bool).maybe(:bool?)
    required(:is_bin, :bool).maybe(:bool?)
    required(:palletizer_incentive_rate, :decimal).filled(:decimal?)
  end
end
