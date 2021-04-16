# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoadProduct
      class ScanBins
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load_product, :scan_bins, id: id, form_values: form_values)
          rules = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/raw_materials/dispatch/bin_load_products/#{id}/allocate",
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action "/raw_materials/dispatch/bin_load_products/#{id}/scan_bins"
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :bin_ids
                end
                row.blank_column
              end
            end
          end

          layout
        end
      end
    end
  end
end
