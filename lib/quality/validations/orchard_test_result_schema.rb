# frozen_string_literal: true

module QualityApp
  OrchardTestUpdateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:orchard_test_type_id, :integer).maybe(:int?)
    optional(:puc_id, :integer).filled(:int?)
    optional(:orchard_id, :integer).filled(:int?)
    optional(:cultivar_id, :integer).maybe(:int?)
    optional(:puc_ids, Types::IntArray).maybe(min_size?: 1) { each(:int?) }
    optional(:orchard_ids, Types::IntArray).maybe(min_size?: 1) { each(:int?) }
    optional(:cultivar_ids, Types::IntArray).maybe(min_size?: 1) { each(:int?) }
    optional(:passed, :bool).maybe(:bool?)
    required(:classification, :bool).maybe(:bool?)
    required(:freeze_result, :bool).maybe(:bool?)
    required(:api_result, :string).maybe(:str?)
    optional(:api_response, :string).maybe(:str?)
    optional(:applicable_from, %i[nil time]).maybe(:time?)
    optional(:applicable_to, %i[nil time]).maybe(:time?)
    optional(:update_all, :bool).maybe(:bool?)
    optional(:group_ids, Types::IntArray).maybe(min_size?: 1) { each(:int?) }
  end
end
