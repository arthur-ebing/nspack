# frozen_string_literal: true

module UiRules
  class RmtContainerMaterialTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::RmtContainerMaterialTypeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'rmt_container_material_type'
    end

    def set_show_fields
      fields[:rmt_container_type] = { renderer: :label,
                                      caption: 'RMT Container Type' }
      fields[:container_material_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:tare_weight] = { renderer: :label }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:container_material_owners] = { renderer: :list,
                                             caption: 'Container Owners',
                                             items: @form_object.container_material_owners }
    end

    def common_fields
      {
        rmt_container_type_id: { renderer: :select,
                                 options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types,
                                 disabled_options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_inactive_rmt_container_types,
                                 caption: 'rmt_container_type',
                                 required: true },
        container_material_type_code: { required: true },
        description: {},
        tare_weight: {},
        party_role_ids: { renderer: :multi,
                          options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_RMT_BIN_OWNER),
                          caption: 'Container Owners',
                          selected: @form_object.party_role_ids,
                          required: false  }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_container_material_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_container_type_id: nil,
                                    container_material_type_code: nil,
                                    description: nil,
                                    tare_weight: nil,
                                    party_role_ids: [])
    end
  end
end
