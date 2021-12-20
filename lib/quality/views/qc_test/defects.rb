# frozen_string_literal: true

module Quality
  module Qc
    module QcTest
      class Defects
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:qc_test, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          # TODO: BACK BUTTON...
          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Defects test'
              form.action "/quality/qc/qc_tests/#{id}/defects"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :sample_size
                end
                row.blank_column
              end
            end

            page.add_grid('defects',
                          "/quality/qc/qc_tests/#{id}/defects_grid",
                          caption: 'QC Defects')
          end
        end
      end
    end
  end
end
