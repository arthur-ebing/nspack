# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module LoadVehicle
      class Edit
        def self.call(load_id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load_vehicle, :edit, load_id: load_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Truck Arrival'
              form.action "/finished_goods/dispatch/loads/#{load_id}/truck_arrival"
              form.remote!
              form.method :update
              form.add_field :load_id
              form.add_field :load_vehicle_id
              form.add_field :vehicle_number
              form.add_field :vehicle_type_id
              form.add_field :haulier_party_role_id
              form.add_field :vehicle_weight_out
              form.add_field :driver_name
              form.add_field :driver_cell_number
              # Container
              form.add_field :container
              form.add_field :load_container_id
              form.add_field :container_code
              form.add_field :container_vents
              form.add_field :container_seal_code
              form.add_field :container_temperature_rhine
              form.add_field :container_temperature_rhine2
              form.add_field :internal_container_code
              form.add_field :max_gross_weight
              if AppConst::CR_FG.verified_gross_mass_required_for_loads?
                form.add_field :tare_weight
                form.add_field :max_payload
                form.add_field :actual_payload
              end
              form.add_field :cargo_temperature_id
              form.add_field :stack_type_id
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
