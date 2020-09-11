# frozen_string_literal: true

module QualityApp
  OrchardTestCreateSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:orchard_test_type_id).filled(:integer)
    required(:puc_id).filled(:integer)
  end

  OrchardTestUpdateSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:orchard_test_type_id).maybe(:integer)
    optional(:puc_id).filled(:integer)
    optional(:orchard_id).filled(:integer)
    optional(:cultivar_id).maybe(:integer)
    optional(:puc_ids).maybe(:array, min_size?: 1).each(:integer)
    optional(:orchard_ids).maybe(:array, min_size?: 1).each(:integer)
    optional(:cultivar_ids).maybe(:array, min_size?: 1).each(:integer)
    optional(:passed).maybe(:bool)
    optional(:classification).maybe(:bool)
    required(:freeze_result).maybe(:bool)
    required(:api_result).maybe(:string)
    optional(:api_response).maybe(:string)
    optional(:update_all).maybe(:bool)
    optional(:group_ids).maybe(:array, min_size?: 1).each(:integer)
  end
end
