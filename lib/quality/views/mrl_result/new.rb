# frozen_string_literal: true

module Quality
  module Mrl
    module MrlResult
      class New
        def self.call(attrs, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:mrl_result, :new, attrs: attrs, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Mrl Result'
              form.action '/quality/mrl/mrl_results'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :farm_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  if rules[:delivery_result]
                    col.add_field :farm_code
                    col.add_field :puc_code
                    col.add_field :orchard_code
                  end
                  col.add_field :production_run_id
                  col.add_field :laboratory_id
                  col.add_field :mrl_sample_type_id
                  col.add_field :fruit_received_at
                  col.add_field :sample_submitted_at
                  col.add_field :pre_harvest_result
                end
                row.column do |col|
                  col.add_field :rmt_delivery_id
                  col.add_field :cultivar_id
                  col.add_field :season_id
                  if rules[:delivery_result]
                    col.add_field :rmt_delivery
                    col.add_field :cultivar_name
                    col.add_field :season_code
                  end
                  col.add_field :num_active_ingredients
                  col.add_field :sample_number
                  col.add_field :reference_number
                  col.add_field :waybill_number
                  col.add_field :ph_level
                  col.add_field :post_harvest_result
                end
              end
            end
          end
        end
      end
    end
  end
end
