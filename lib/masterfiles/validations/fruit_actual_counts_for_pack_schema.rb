# frozen_string_literal: true

module MasterfilesApp
  FruitActualCountsForPackSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:std_fruit_size_count_id).filled(:integer)
    required(:basic_pack_code_id).filled(:integer)
    required(:actual_count_for_pack).filled(:integer)
    required(:standard_pack_code_ids).maybe(:array).each(:integer)
    required(:size_reference_ids).maybe(:array).each(:integer)
  end
end
