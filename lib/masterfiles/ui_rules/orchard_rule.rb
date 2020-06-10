# frozen_string_literal: true

module UiRules
  class OrchardRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if @options[:id]

      form_name 'orchard'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      farm_id_label = @repo.find_farm(@form_object.farm_id)&.farm_code
      puc_id_label = @repo.find_puc(@form_object.puc_id)&.puc_code
      farm_manager_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.farm_manager_party_role_id)&.party_name
      fields[:farm_id] = { renderer: :label, with_value: farm_id_label, caption: 'Farm' }
      fields[:puc_id] = { renderer: :label, with_value: puc_id_label, caption: 'Puc' }
      fields[:orchard_code] = { renderer: :label }
      fields[:farm_section_name] = { renderer: :label }
      fields[:farm_manager_party_role_id] = { renderer: :label, with_value: farm_manager_party_role_id_label, caption: 'Farm Manager' }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:cultivar_ids] = { renderer: :list, items: cultivar_names, caption: 'Cultivars'  }
    end

    def common_fields
      farm_id = @options[:farm_id] || @repo.find_orchard(@options[:id]).farm_id
      farm_id_label = @repo.find_farm(farm_id)&.farm_code
      {
        farm: { renderer: :label, with_value: farm_id_label, caption: 'Farm', readonly: true },
        farm_id: { renderer: :hidden, value: farm_id },
        puc_id: { renderer: :select,
                  options: @repo.selected_farm_pucs(farm_id),
                  disabled_options: @repo.for_select_inactive_pucs,
                  caption: 'Puc',
                  required: true },
        orchard_code: { required: true },
        description: {},
        active: { renderer: :checkbox },
        cultivar_ids: { renderer: :multi,
                        options: MasterfilesApp::CultivarRepo.new.for_select_cultivars,
                        selected: @form_object.cultivar_ids,
                        caption: 'Cultivars',
                        required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_orchard(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(farm_id: @options[:farm_id],
                                    puc_id: nil,
                                    orchard_code: nil,
                                    description: nil,
                                    active: true,
                                    cultivar_ids: [])
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id, notify: [{ url: "/masterfiles/farms/orchards/#{@options[:id]}/farm_changed" }]
      end
    end

    def cultivar_names
      @repo.find_cultivar_names(@options[:id])
    end
  end
end
