# frozen_string_literal: true

module RawMaterialsApp
  PresortStagingRunChildSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:presort_staging_run_id).maybe(:integer)
    optional(:completed_at).maybe(:time)
    optional(:staged_at).maybe(:time)
    optional(:canceled).maybe(:bool)
    required(:farm_id).filled(:integer)
    optional(:editing).maybe(:bool)
    optional(:staged).maybe(:bool)
    optional(:running).maybe(:bool)
  end
end
