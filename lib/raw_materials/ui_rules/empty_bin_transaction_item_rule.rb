# frozen_string_literal: true

module UiRules
  class EmptyBinTransactionItemRule < Base
    def generate_rules
      @repo = RawMaterialsApp::EmptyBinsRepo.new
      make_form_object
      apply_form_values
      add_behaviours

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'empty_bin_transaction_item'
    end

    def set_show_fields
      # rmt_container_material_owner_id_label = RawMaterialsApp::RmtContainerMaterialOwnerRepo.new.find_rmt_container_material_owner(@form_object.rmt_container_material_owner_id)&.id
      rmt_container_material_owner_id_label = @repo.find(:rmt_container_material_owners, RawMaterialsApp::RmtContainerMaterialOwner, @form_object.rmt_container_material_owner_id)&.id
      # empty_bin_from_location_id_label = RawMaterialsApp::LocationRepo.new.find_location(@form_object.empty_bin_from_location_id)&.location_long_code
      empty_bin_from_location_id_label = @repo.find(:locations, RawMaterialsApp::Location, @form_object.empty_bin_from_location_id)&.location_long_code
      # empty_bin_to_location_id_label = RawMaterialsApp::LocationRepo.new.find_location(@form_object.empty_bin_to_location_id)&.location_long_code
      empty_bin_to_location_id_label = @repo.find(:locations, RawMaterialsApp::Location, @form_object.empty_bin_to_location_id)&.location_long_code
      fields[:rmt_container_material_owner_id] = { renderer: :label, with_value: rmt_container_material_owner_id_label, caption: 'Rmt Container Material Owner' }
      fields[:empty_bin_from_location_id] = { renderer: :label, with_value: empty_bin_from_location_id_label, caption: 'Empty Bin From Location' }
      fields[:empty_bin_to_location_id] = { renderer: :label, with_value: empty_bin_to_location_id_label, caption: 'Empty Bin To Location' }
      fields[:quantity_bins] = { renderer: :label }
    end

    def common_fields
      {
        rmt_container_material_owner_id: { renderer: :select,
                                           options: @repo.for_select_empty_bin_owners,
                                           # selected: MasterfilesApp::PartyRepo.new.implementation_owner_party_role.id,
                                           min_charwidth: 30,
                                           caption: 'Owner',
                                           required: true },
        rmt_container_material_type_id: { renderer: :select,
                                          options: [],
                                          required: true,
                                          caption: 'Type' },
        quantity_bins: { renderer: :integer, required: true },
        empty_bin_type_ids: { renderer: :select, options: bin_sets, prompt: true, caption: 'Bin Sets' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_empty_bin_transaction_item(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_container_material_owner_id: nil,
                                    rmt_container_material_type_id: nil,
                                    quantity_bins: nil)
    end

    def onsite_empty_bin_location_id
      @repo.onsite_empty_bin_location_id
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        owner_changed_url = '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/owner_changed'
        behaviour.dropdown_change :rmt_container_material_owner_id, notify: [{ url: owner_changed_url }]
      end
    end

    def bin_sets
      @options[:interactor]&.stepper&.for_select_bin_sets || []
    end
  end
end
