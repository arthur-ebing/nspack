# frozen_string_literal: true

module Quality
  module Qc
    module QcTest
      class Defects
        def self.call(id, redirect_url:, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:qc_test, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_text rules[:compact_header]
              section.add_control control_type: :link, text: 'Back', url: redirect_url, style: :back_button
            end
            page.form do |form|
              form.caption 'Defects test'
              form.action "/quality/qc/qc_tests/#{id}/defects"
              form.remote!
              form.method :update
              form.inline!
              form.add_field :sample_size
              form.submit_captions 'Change'
            end

            page.section do |section|
              section.fit_height!
              section.add_grid('defects',
                               "/quality/qc/qc_tests/#{id}/defects_grid",
                               caption: 'QC Defects')
            end
          end
        end
      end
    end
  end
end
