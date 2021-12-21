# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class Select
        def self.call(test_type: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:qc_sample, :select)
          rules   = ui_rule.compile
          action = if test_type.nil?
                     '/quality/qc/qc_samples/select'
                   else
                     "/quality/qc/qc_samples/select/#{test_type}"
                   end

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Select QC Sample'
              form.remote! if remote
              form.action action
              form.row do |row|
                row.column do |col|
                  col.add_field :id
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
