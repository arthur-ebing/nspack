# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class SelectTest
        def self.call(id, remote: true)
          ui_rule = UiRules::Compiler.new(:qc_sample, :select_test, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Select Test for QC Sample'
              form.remote! if remote
              form.action "/quality/qc/qc_samples/#{id}/select_test"
              form.add_field :id
              form.add_field :ref_number
              form.add_field :short_description
              form.add_field :sample_size
              form.add_field :qc_test_type_id
            end
            # Add links to existing tests here
            if rules[:existing_tests].length.nonzero?
              page.section do |section|
                section.add_control(control_type: :dropdown_button, text: 'Existing tests', style: :action_button, items: rules[:existing_tests])
              end
            end
          end
        end
      end
    end
  end
end
