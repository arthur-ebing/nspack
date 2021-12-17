# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qc_sample, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Qc Sample'
              form.view_only!
              form.add_field :qc_sample_type_id
              form.add_field :ref_number
              form.add_field :short_description
              form.add_field :context
              form.add_field :sample_size
              form.add_field :editing
              form.add_field :completed
              form.add_field :completed_at
              form.add_field :starch_summary
              # form.add_field :rmt_delivery_id
              # form.add_field :coldroom_location_id
              # form.add_field :production_run_id
              # form.add_field :orchard_id
              # form.add_field :presort_run_lot_number
              # form.add_field :rmt_bin_ids
            end
          end
        end
      end
    end
  end
end
