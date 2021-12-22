# frozen_string_literal: true

module Quality
  module Mrl
    module MrlResult
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:mrl_result, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Mrl Result'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :farm_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :production_run_id
                  col.add_field :laboratory_id
                  col.add_field :mrl_sample_type_id
                  col.add_field :fruit_received_at
                  col.add_field :sample_submitted_at
                  col.add_field :result_received_at
                  col.add_field :mrl_sample_passed
                  col.add_field :pre_harvest_result
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :rmt_delivery_id
                  col.add_field :cultivar_id
                  col.add_field :season_id
                  col.add_field :num_active_ingredients
                  col.add_field :sample_number
                  col.add_field :reference_number
                  col.add_field :waybill_number
                  col.add_field :ph_level
                  col.add_field :max_num_chemicals_passed
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
