# frozen_string_literal: true

module UiRules
  class PalletMixRuleRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      @resource_repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values
      common_values_for_fields common_fields
      set_show_fields if %i[show reopen].include? @mode
      add_behaviours
      form_name 'pallet_mix_rule'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      packhouse_plant_resource_id_label = @resource_repo.find_plant_resource(@form_object.packhouse_plant_resource_id)&.plant_resource_code
      fields[:scope] = { renderer: :label }
      # fields[:production_run_id] = { renderer: :label }
      # fields[:pallet_id] = { renderer: :label }
      fields[:allow_tm_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_grade_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_size_ref_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_pack_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_std_count_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_mark_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_inventory_code_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_cultivar_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_cultivar_group_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_puc_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_orchard_mix] = { renderer: :label, as_boolean: true }
      fields[:packhouse_plant_resource_id] = { renderer: :label, with_value: packhouse_plant_resource_id_label, caption: 'Packhouse Plant Resource' }
      fields[:allow_variety_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_marketing_org_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_sell_by_mix] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        toggle: { renderer: :checkbox, caption: 'All' },
        scope: { readonly: true },
        allow_tm_mix: { renderer: :checkbox },
        allow_grade_mix: { renderer: :checkbox },
        allow_size_ref_mix: { renderer: :checkbox },
        allow_pack_mix: { renderer: :checkbox },
        allow_std_count_mix: { renderer: :checkbox },
        allow_mark_mix: { renderer: :checkbox },
        allow_inventory_code_mix: { renderer: :checkbox },
        allow_cultivar_mix: { renderer: :checkbox },
        allow_cultivar_group_mix: { renderer: :checkbox },
        allow_puc_mix: { renderer: :checkbox },
        allow_orchard_mix: { renderer: :checkbox },
        allow_variety_mix: { renderer: :checkbox },
        allow_marketing_org_mix: { renderer: :checkbox },
        allow_sell_by_mix: { renderer: :checkbox }
        # packhouse_plant_resource_id: { renderer: :select, options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE),
        #                                caption: 'PH Plant Resource', prompt: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = OpenStruct.new(@repo.find_pallet_mix_rule(@options[:id]).to_h.merge!(toggle: false))
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(ProductionApp::PalletMixRule)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :toggle, notify: [{ url: '/production/runs/toggle' }]
      end
    end
  end
end
