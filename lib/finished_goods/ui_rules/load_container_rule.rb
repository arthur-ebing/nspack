# frozen_string_literal: true

module UiRules
  class LoadContainerRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::LoadContainerRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'load_container'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      # load_id_label = FinishedGoodsApp::LoadRepo.new.find_load(@form_object.load_id)&.edi_file_name
      load_id_label = @repo.find(:loads, FinishedGoodsApp::Load, @form_object.load_id)&.edi_file_name
      # cargo_temperature_id_label = FinishedGoodsApp::CargoTemperatureRepo.new.find_cargo_temperature(@form_object.cargo_temperature_id)&.temperature_code
      cargo_temperature_id_label = @repo.find(:cargo_temperatures, FinishedGoodsApp::CargoTemperature, @form_object.cargo_temperature_id)&.temperature_code
      # stack_type_id_label = FinishedGoodsApp::ContainerStackTypeRepo.new.find_container_stack_type(@form_object.stack_type_id)&.stack_type_code
      stack_type_id_label = @repo.find(:container_stack_types, FinishedGoodsApp::ContainerStackType, @form_object.stack_type_id)&.stack_type_code
      fields[:load_id] = { renderer: :label, with_value: load_id_label, caption: 'Load' }
      fields[:container_code] = { renderer: :label }
      fields[:container_vents] = { renderer: :label }
      fields[:container_seal_code] = { renderer: :label }
      fields[:container_temperature_rhine] = { renderer: :label }
      fields[:container_temperature_rhine2] = { renderer: :label }
      fields[:internal_container_code] = { renderer: :label }
      fields[:max_gross_weight] = { renderer: :label }
      fields[:tare_weight] = { renderer: :label }
      fields[:max_payload] = { renderer: :label }
      fields[:actual_payload] = { renderer: :label }
      fields[:verified_gross_weight] = { renderer: :label }
      fields[:verified_gross_weight_date] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:cargo_temperature_id] = { renderer: :label, with_value: cargo_temperature_id_label, caption: 'Cargo Temperature' }
      fields[:stack_type_id] = { renderer: :label, with_value: stack_type_id_label, caption: 'Stack Type' }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_LOAD_CONTAINER_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        load_id: { renderer: :select, options: FinishedGoodsApp::LoadRepo.new.for_select_loads, disabled_options: FinishedGoodsApp::LoadRepo.new.for_select_inactive_loads, caption: 'Load', required: true },
        container_code: { required: true },
        container_vents: {},
        container_seal_code: { required: true },
        container_temperature_rhine: {},
        container_temperature_rhine2: {},
        internal_container_code: { required: true },
        max_gross_weight: {},
        tare_weight: {},
        max_payload: {},
        actual_payload: {},
        verified_gross_weight: {},
        verified_gross_weight_date: {},
        cargo_temperature_id: { renderer: :select, options: FinishedGoodsApp::CargoTemperatureRepo.new.for_select_cargo_temperatures, disabled_options: FinishedGoodsApp::CargoTemperatureRepo.new.for_select_inactive_cargo_temperatures, caption: 'Cargo Temperature', required: true },
        stack_type_id: { renderer: :select, options: FinishedGoodsApp::ContainerStackTypeRepo.new.for_select_container_stack_types, disabled_options: FinishedGoodsApp::ContainerStackTypeRepo.new.for_select_inactive_container_stack_types, caption: 'Stack Type', required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_load_container(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(load_id: nil,
                                    container_code: nil,
                                    container_vents: nil,
                                    container_seal_code: nil,
                                    container_temperature_rhine: nil,
                                    container_temperature_rhine2: nil,
                                    internal_container_code: nil,
                                    max_gross_weight: nil,
                                    tare_weight: nil,
                                    max_payload: nil,
                                    actual_payload: nil,
                                    verified_gross_weight: nil,
                                    verified_gross_weight_date: nil,
                                    cargo_temperature_id: nil,
                                    stack_type_id: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
