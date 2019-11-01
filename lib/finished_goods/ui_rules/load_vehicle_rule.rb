# frozen_string_literal: true

module UiRules
  class LoadVehicleRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::LoadVehicleRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'load_vehicle'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      load_id_label = FinishedGoodsApp::LoadRepo.new.find_load(@form_object.load_id)&.edi_file_name
      # load_id_label = @repo.find(:loads, FinishedGoodsApp::Load, @form_object.load_id)&.edi_file_name
      vehicle_type_id_label = FinishedGoodsApp::VehicleTypeRepo.new.find_vehicle_type(@form_object.vehicle_type_id)&.vehicle_type_code
      # vehicle_type_id_label = @repo.find(:vehicle_types, FinishedGoodsApp::VehicleType, @form_object.vehicle_type_id)&.vehicle_type_code
      haulier_party_role_id_label = FinishedGoodsApp::PartyRoleRepo.new.find_party_role(@form_object.haulier_party_role_id)&.id
      # haulier_party_role_id_label = @repo.find(:party_roles, FinishedGoodsApp::PartyRole, @form_object.haulier_party_role_id)&.id
      fields[:load_id] = { renderer: :label, with_value: load_id_label, caption: 'Load' }
      fields[:vehicle_type_id] = { renderer: :label, with_value: vehicle_type_id_label, caption: 'Vehicle Type' }
      fields[:haulier_party_role_id] = { renderer: :label, with_value: haulier_party_role_id_label, caption: 'Haulier Party Role' }
      fields[:vehicle_number] = { renderer: :label }
      fields[:vehicle_weight_out] = { renderer: :label }
      fields[:dispatch_consignment_note_number] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_LOAD_VEHICLE_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        load_id: { renderer: :select,
                   options: FinishedGoodsApp::LoadRepo.new.for_select_loads,
                   caption: 'Load',
                   required: true },
        vehicle_type_id: { renderer: :select,
                           options: MasterfilesApp::VehicleTypeRepo.new.for_select_vehicle_types,
                           caption: 'Vehicle Type',
                           required: true },
        haulier_party_role_id: { renderer: :select,
                                 options: MasterfilesApp::PartyRepo.new.for_select_party_roles,
                                 caption: 'Haulier Party Role',
                                 required: true },
        vehicle_number: { required: true },
        vehicle_weight_out: {},
        dispatch_consignment_note_number: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_load_vehicle(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(load_id: nil,
                                    vehicle_type_id: nil,
                                    haulier_party_role_id: nil,
                                    vehicle_number: nil,
                                    vehicle_weight_out: nil,
                                    dispatch_consignment_note_number: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
