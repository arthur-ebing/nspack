# frozen_string_literal: true

module MasterfilesApp
  CommoditySchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:commodity_group_id, :integer).filled(:int?)
    required(:code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).filled(:str?)
    required(:hs_code, Types::StrippedString).filled(:str?)
    required(:requires_standard_counts, :bool).maybe(:bool?)
    required(:use_size_ref_for_edi, :bool).maybe(:bool?)
    # required(:active, :bool).filled(:bool?)
  end
end
