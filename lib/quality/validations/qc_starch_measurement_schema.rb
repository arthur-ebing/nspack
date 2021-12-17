# frozen_string_literal: true

module QualityApp
  QcStarchMeasurementSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qc_test_id).filled(:integer)
    required(:starch_percentage).filled(:integer)
    required(:qty_fruit_with_percentage).filled(:integer)
  end

  class QcStarchTestContract < Dry::Validation::Contract
    params do
      required(:sample_size).filled(:integer)
      required(:percentage5).maybe(:integer)
      required(:percentage10).maybe(:integer)
      required(:percentage20).maybe(:integer)
      required(:percentage25).maybe(:integer)
      required(:percentage30).maybe(:integer)
      required(:percentage40).maybe(:integer)
      required(:percentage60).maybe(:integer)
      required(:percentage70).maybe(:integer)
      required(:percentage80).maybe(:integer)
    end

    rule(:sample_size) do
      tot = (values[:percentage5] || 0) +
            (values[:percentage10] || 0) +
            (values[:percentage20] || 0) +
            (values[:percentage25] || 0) +
            (values[:percentage30] || 0) +
            (values[:percentage40] || 0) +
            (values[:percentage60] || 0) +
            (values[:percentage70] || 0) +
            (values[:percentage80] || 0)
      key.failure 'cannot be less than the total test quantity' if values[:sample_size] < tot
    end
  end
end
