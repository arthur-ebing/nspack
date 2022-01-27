# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:qc_sample, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Qc Sample'
              form.action "/quality/qc/qc_samples/#{id}"
              form.remote!
              form.method :update
              form.add_field :id
              form.add_field :qc_sample_type_id
              form.add_field :presort_run_lot_number
              form.add_field :rmt_delivery_id
              form.add_field :coldroom_location_id
              form.add_field :production_run_id
              form.add_field :orchard_id
              form.add_field :context
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
