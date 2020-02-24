# frozen_string_literal: true

module QualityApp
  OrchardTestCreateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:orchard_test_type_id, :integer).filled(:int?)
  end
  OrchardTestUpdateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:orchard_test_type_id, :integer).maybe(:int?)
    required(:orchard_set_result_id, :integer).maybe(:int?)
    required(:orchard_id, :integer).maybe(:int?)
    required(:puc_id, :integer).maybe(:int?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:status_description, Types::StrippedString).maybe(:str?)
    required(:passed, :bool).maybe(:bool?)
    required(:classification_only, :bool).maybe(:bool?)
    required(:freeze_result, :bool).maybe(:bool?)
    required(:api_result, :hash).maybe(:hash?)
    required(:classifications, :string).maybe(:str?)
    optional(:cultivar_ids, Types::IntArray).maybe { each(:int?) }
    required(:applicable_from, :time).filled(:time?)
    required(:applicable_to, :time).filled(:time?)
  end
end
