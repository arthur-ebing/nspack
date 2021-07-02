# frozen_string_literal: true

module Production
  module Runs
    module Rebins
      class CreateRebins
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rebin, :new, production_run_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'New Bin'
              form.action "/production/runs/production_runs/#{id}/rebins"
              form.remote! if remote
              form.add_field :qty_bins_to_create
              form.add_field :rmt_class_id
              form.add_field :farm_code
              form.add_field :puc_code
              form.add_field :orchard_code
              form.add_field :cultivar_name
              form.add_field :cultivar_group_code
              form.add_field :season_code
              form.add_field :bin_fullness
              form.add_field :nett_weight if rules[:show_nett_weight]
              form.add_field :rmt_container_material_type_id
              form.add_field :rmt_material_owner_party_role_id if rules[:capture_container_material_owner]
              form.add_field :gross_weight
            end
          end

          layout
        end
      end
    end
  end
end
