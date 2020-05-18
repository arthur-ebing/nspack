# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoad
      class Complete
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load, :complete, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Complete Bin Load'
              form.action "/raw_materials/dispatch/bin_loads/#{id}/complete"
              form.remote!
              form.submit_captions 'Complete'
              form.add_text 'Are you sure you want to complete this bin load?', wrapper: :h3
              form.add_field :bin_load_purpose_id
              form.add_field :customer_party_role_id
              form.add_field :transporter_party_role_id
              form.add_field :dest_depot_id
              form.add_field :qty_bins
            end
            page.section do |section|
              section.add_grid('bin_load_products',
                               "/list/bin_load_products/grid?key=standard&bin_load_id=#{id}",
                               caption: 'Bin Load Products',
                               height: 40)
            end
          end

          layout
        end
      end
    end
  end
end
