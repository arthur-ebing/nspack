# frozen_string_literal: true

module UiRules
  class PersonnelIdentifierRule < Base
    def generate_rules
      @repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show
      set_link_fields if @mode == :link
      set_de_link_fields if @mode == :de_link

      form_name 'personnel_identifier'
    end

    def set_link_fields
      fields[:identifier] = { renderer: :label }
      fields[:contract_worker_id] = { renderer: :select,
                                      options: @repo.for_select_unallocated_contract_workers,
                                      required: true,
                                      searchable: true }
    end

    def set_de_link_fields
      contract_worker = @repo.find_contract_worker_by_identifier_id(@options[:id])
      fields[:identifier] = { renderer: :label }
      fields[:contract_worker_id] = { renderer: :label, with_value: contract_worker[:contract_worker_name] }
    end

    def set_show_fields
      fields[:hardware_type] = { renderer: :label }
      fields[:identifier] = { renderer: :label }
      fields[:in_use] = { renderer: :label, as_boolean: true }
      fields[:available_from] = { renderer: :label }
    end

    def common_fields
      {
        hardware_type: { required: true },
        identifier: { required: true },
        in_use: { renderer: :checkbox },
        available_from: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_personnel_identifier(@options[:id])
      @form_object = OpenStruct.new(@form_object.to_h.merge(contract_worker_id: nil)) if %i[link de_link].include?(@mode)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(hardware_type: nil,
                                    identifier: nil,
                                    in_use: nil,
                                    available_from: nil)
    end
  end
end
