# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class New
        def self.call(qc_sample_type_id, context:, id:, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/ParameterLists
          ui_rule = UiRules::Compiler.new(:qc_sample, :new, qc_sample_type_id: qc_sample_type_id, context: context, context_key: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Qc Sample'
              form.action '/quality/qc/qc_samples'
              form.remote! if remote
              form.add_field :context
              form.add_field :context_key
              form.add_field :qc_sample_type_id
              form.add_field :rmt_delivery_id
              form.add_field :coldroom_location_id
              form.add_field :production_run_id
              form.add_field :orchard_id
              form.add_field :presort_run_lot_number
              form.add_field :ref_number
              form.add_field :sample_size
              form.add_field :drawn_at
              form.add_field :short_description
              # form.add_field :editing
              # form.add_field :completed
              # form.add_field :completed_at
              # form.add_field :rmt_bin_ids
            end
          end
        end
      end
    end
  end
end
