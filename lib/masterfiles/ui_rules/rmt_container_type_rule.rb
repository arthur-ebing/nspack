# frozen_string_literal: true

module UiRules
  class RmtContainerTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::RmtContainerTypeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      set_edit_fields if @mode == :edit
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'rmt_container_type'
    end

    def set_show_fields
      rmt_inner_container_type_id_label = MasterfilesApp::RmtContainerTypeRepo.new.find_container_type(@form_object.rmt_inner_container_type_id)&.container_type_code
      fields[:rmt_inner_container_type_id] = { renderer: :label, with_value: rmt_inner_container_type_id_label }
      fields[:container_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:tare_weight] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def set_edit_fields
      fields[:active] = { renderer: :checkbox }
    end

    def common_fields
      {
        # where_clause = (@form_object.id ? "id <> #{@form_object.id}" : true)
        rmt_inner_container_type_id: { renderer: :select, options: MasterfilesApp::RmtContainerTypeRepo.new.find_inner_container_types(@form_object.id ? "id <> #{@form_object.id}" : true),  # (where: (@form_object.id : ? true)),
                                       disabled_options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_inactive_rmt_container_types,
                                       caption: 'Inner Container Type Code', prompt: 'Inner Container Type Code' },
        container_type_code: { required: true },
        tare_weight: {},
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_container_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(container_type_code: nil,
                                    description: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
