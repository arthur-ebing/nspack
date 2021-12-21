# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class Reopen
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qc_sample, :reopen, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Reopen Qc Sample'
              form.action "/quality/qc/qc_samples/#{id}/reopen"
              form.remote!
              form.submit_captions 'Reopen'
              form.add_text 'Are you sure you want to reopen this qc_sample for editing?', wrapper: :h3
              form.add_field :qc_sample_type_id
              form.add_field :rmt_delivery_id
              form.add_field :coldroom_location_id
              form.add_field :production_run_id
              form.add_field :orchard_id
              form.add_field :presort_run_lot_number
              form.add_field :ref_number
              form.add_field :short_description
              form.add_field :sample_size
              form.add_field :editing
              form.add_field :completed
              form.add_field :completed_at
              form.add_field :rmt_bin_ids
            end
          end
        end
      end
    end
  end
end
