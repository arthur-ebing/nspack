# frozen_string_literal: true

module Quality
  module Mrl
    module MrlResult
      class CaptureResult
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:mrl_result, :capture_result, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Capture Mrl Result'
              form.action "/quality/mrl/mrl_results/#{id}/capture_mrl_result"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :result_received_at
                  col.add_field :mrl_sample_passed
                  col.add_field :max_num_chemicals_passed
                end
                row.blank_column
              end
            end
          end
        end
      end
    end
  end
end
