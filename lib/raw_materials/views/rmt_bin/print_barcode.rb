# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtBin
      class PrintBarcode
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_bin, :print_barcode, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/raw_materials/deliveries/rmt_bins/#{id}/print_barcode"
              form.remote!
              form.method :update
              form.add_field :farm_id
              form.add_field :orchard_id
              form.add_field :season_id
              form.add_field :cultivar_id
              form.add_field :printer
            end
          end

          layout
        end
      end
    end
  end
end
