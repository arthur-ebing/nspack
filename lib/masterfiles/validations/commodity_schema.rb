# frozen_string_literal: true

module MasterfilesApp
  CommoditySchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:commodity_group_id).filled(:integer)
    required(:code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
    required(:hs_code).maybe(Types::StrippedString)
    required(:requires_standard_counts).maybe(:bool)
    required(:use_size_ref_for_edi).maybe(:bool)
    required(:colour_applies).maybe(:bool)
    required(:allocate_sample_rmt_bins).filled(:bool)
  end
end
