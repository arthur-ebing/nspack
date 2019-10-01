# frozen_string_literal: true

module UiRules
  class VoyageRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::VoyageRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'voyage'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      # vessel_id_label = FinishedGoodsApp::VesselRepo.new.find_vessel(@form_object.vessel_id)&.vessel_code
      vessel_id_label = @repo.find(:vessels, MasterfilesApp::Vessel, @form_object.vessel_id)&.vessel_code
      # voyage_type_id_label = FinishedGoodsApp::VoyageTypeRepo.new.find_voyage_type(@form_object.voyage_type_id)&.voyage_type_code
      voyage_type_id_label = @repo.find(:voyage_types, MasterfilesApp::VoyageType, @form_object.voyage_type_id)&.voyage_type_code
      fields[:vessel_id] = { renderer: :label, with_value: vessel_id_label, caption: 'Vessel' }
      fields[:voyage_type_id] = { renderer: :label, with_value: voyage_type_id_label, caption: 'Voyage Type' }
      fields[:voyage_number] = { renderer: :label }
      fields[:voyage_code] = { renderer: :label }
      fields[:year] = { renderer: :label }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label }
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
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_VOYAGE_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        vessel_id: { renderer: :select, options: MasterfilesApp::VesselRepo.new.for_select_vessels, disabled_options: MasterfilesApp::VesselRepo.new.for_select_inactive_vessels, caption: 'Vessel', required: true },
        voyage_type_id: { renderer: :select, options: MasterfilesApp::VoyageTypeRepo.new.for_select_voyage_types, disabled_options: MasterfilesApp::VoyageTypeRepo.new.for_select_inactive_voyage_types, caption: 'Voyage Type', required: true },
        voyage_number: { required: true },
        voyage_code: { required: true },
        year: {},
        completed: { renderer: :checkbox },
        completed_at: { renderer: :label }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_voyage(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(vessel_id: nil,
                                    voyage_type_id: nil,
                                    voyage_number: nil,
                                    voyage_code: nil,
                                    year: nil,
                                    completed: nil,
                                    completed_at: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
