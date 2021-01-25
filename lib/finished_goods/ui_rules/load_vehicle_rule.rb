# frozen_string_literal: true

module UiRules
  class LoadVehicleRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = FinishedGoodsApp::LoadVehicleRepo.new
      @container_repo = FinishedGoodsApp::LoadContainerRepo.new
      make_form_object
      apply_form_values
      add_behaviours

      common_values_for_fields common_fields

      form_name 'load_vehicle'
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      container = @form_object.container == 't'
      {
        load_id: { renderer: :hidden,
                   with_value: @form_object.load_id,
                   caption: 'Load' },
        load_vehicle_id: { renderer: :hidden },
        vehicle_type_id: { renderer: :select,
                           options: MasterfilesApp::VehicleTypeRepo.new.for_select_vehicle_types,
                           disabled_options: MasterfilesApp::VehicleTypeRepo.new.for_select_inactive_vehicle_types,
                           caption: 'Vehicle Type',
                           prompt: true,
                           required: true },
        haulier_party_role_id: { renderer: :select,
                                 options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_HAULIER),
                                 disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_HAULIER),
                                 caption: 'Haulier',
                                 prompt: true,
                                 required: true },
        vehicle_number: { required: true },
        vehicle_weight_out: { renderer: :numeric },
        driver_name: { caption: 'Driver',
                       required: true },
        driver_cell_number: { renderer: :numeric,
                              required: true },
        # container
        container: { renderer: :select,
                     options: [%w[No f], %w[Yes t]],
                     caption: 'Container?',
                     required: true },
        load_container_id: { renderer: :hidden },
        container_code: { hide_on_load: !container,
                          required: container },
        container_vents: { hide_on_load: !container },
        container_seal_code: { hide_on_load: !container },
        container_temperature_rhine: { hide_on_load: !container,
                                       required: container },
        container_temperature_rhine2: { hide_on_load: !container },
        internal_container_code: { hide_on_load: !container },
        max_gross_weight: { renderer: :numeric,
                            hide_on_load: !container,
                            required: container },
        tare_weight: { renderer: :numeric,
                       hide_on_load: !container,
                       required: container },
        max_payload: { renderer: :numeric,
                       hide_on_load: !container,
                       required: container },
        actual_payload: { renderer: :numeric,
                          hide_on_load: !container },
        cargo_temperature_id: { renderer: :select,
                                options: MasterfilesApp::CargoTemperatureRepo.new.for_select_cargo_temperatures,
                                disabled_options: MasterfilesApp::CargoTemperatureRepo.new.for_select_inactive_cargo_temperatures,
                                caption: 'Cargo Temperature',
                                hide_on_load: !container },
        stack_type_id: { renderer: :select,
                         options: @container_repo.for_select_container_stack_types,
                         disabled_options: @container_repo.for_select_inactive_container_stack_types,
                         caption: 'Stack Type',
                         hide_on_load: !container }
      }
    end

    def make_form_object
      load_vehicle_id = @repo.get_id(:load_vehicles, load_id: @options[:load_id])
      load_container_id = @repo.get_id(:load_containers, load_id: @options[:load_id])

      return make_new_form_object if load_vehicle_id.nil?

      hash = @repo.find_load_vehicle_flat(load_vehicle_id).to_h
      hash.merge!(@container_repo.find_load_container_flat(load_container_id).to_h)
      hash[:container] = !load_container_id.nil? ? 't' : 'f'
      @form_object = OpenStruct.new(hash)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(load_id: @options[:load_id],
                                    load_vehicle_id: nil,
                                    vehicle_type_id: nil,
                                    haulier_party_role_id: nil,
                                    vehicle_number: nil,
                                    vehicle_weight_out: nil,
                                    dispatch_consignment_note_number: nil,
                                    driver_name: nil,
                                    driver_cell_number: nil,
                                    container: 'f',
                                    load_container_id: nil,
                                    container_code: nil,
                                    container_vents: nil,
                                    container_seal_code: nil,
                                    container_temperature_rhine: nil,
                                    container_temperature_rhine2: nil,
                                    internal_container_code: nil,
                                    max_gross_weight: nil,
                                    tare_weight: nil,
                                    max_payload: nil,
                                    actual_payload: @container_repo.calculate_actual_payload(@options[:load_id]),
                                    cargo_temperature_id: nil,
                                    stack_type_id: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :vehicle_type_id, notify: [{ url: '/finished_goods/dispatch/loads/container_changed' }]
        behaviour.dropdown_change :container, notify: [{ url: '/finished_goods/dispatch/loads/container_changed' }]
      end
    end
  end
end
