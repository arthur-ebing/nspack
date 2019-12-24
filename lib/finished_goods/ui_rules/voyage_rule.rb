# frozen_string_literal: true

module UiRules
  class VoyageRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = FinishedGoodsApp::VoyageRepo.new
      make_form_object
      add_rules
      apply_form_values

      if @mode == :edit
        hash = common_fields
        hash[:voyage_type_id][:disabled_options] = hash[:voyage_type_id].delete :options
        common_values_for_fields hash
      else
        common_values_for_fields common_fields
      end

      set_show_fields if %i[show complete].include? @mode
      add_behaviours
      form_name 'voyage'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      vessel_id_label = MasterfilesApp::VesselRepo.new.find_vessel(@form_object.vessel_id)&.vessel_code
      voyage_type_id_label = MasterfilesApp::VoyageTypeRepo.new.find_voyage_type(@form_object.voyage_type_id)&.voyage_type_code
      fields[:vessel_id] = { renderer: :label, with_value: vessel_id_label, caption: 'Vessel' }
      fields[:voyage_type_id] = { renderer: :label, with_value: voyage_type_id_label, caption: 'Voyage Type' }
      fields[:voyage_number] = { renderer: :label }
      fields[:voyage_code] = { renderer: :label }
      fields[:year] = { renderer: :label }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label, hide_on_load: @mode == :complete }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        voyage_type_id: { renderer: :select,
                          options: MasterfilesApp::VoyageTypeRepo.new.for_select_voyage_types,
                          disabled_options: MasterfilesApp::VoyageTypeRepo.new.for_select_inactive_voyage_types,
                          caption: 'Voyage Type',
                          prompt: true,
                          required: true,
                          disabled: false },
        vessel_id: { renderer: :select,
                     options: MasterfilesApp::VesselRepo.new.for_select_vessels(voyage_type_id: @form_object.voyage_type_id),
                     disabled_options: MasterfilesApp::VesselRepo.new.for_select_inactive_vessels(voyage_type_id: @form_object.voyage_type_id),
                     caption: 'Vessel',
                     prompt: true,
                     required: true },
        voyage_number: { required: true },
        voyage_code: { readonly: true,
                       hide_on_load: @mode == :new },
        year: { renderer: :input, subtype: :integer },
        completed: { renderer: :checkbox,
                     disabled: !@form_object.completed,
                     hide_on_load: @mode == :new },
        completed_at: { renderer: :label,
                        disabled: true,
                        hide_on_load: @mode == :new }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_voyage(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(vessel_id: nil,
                                    voyage_type_id: nil,
                                    voyage_number: nil,
                                    voyage_code: nil,
                                    year: DateTime.now.year,
                                    completed: false,
                                    completed_at: nil)
    end

    private

    def add_rules
      pol_port_type_id = @repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POL)
      pod_port_type_id = @repo.get_with_args(:port_types, :id, port_type_code: AppConst::PORT_TYPE_POD)
      has_pod =  @repo.exists?(:voyage_ports, voyage_id: @form_object.id, port_type_id: pol_port_type_id)
      has_pol =  @repo.exists?(:voyage_ports, voyage_id: @form_object.id, port_type_id: pod_port_type_id)

      rules[:can_complete] = (has_pol & has_pod & !@form_object.completed)
      rules[:completed] = @form_object.completed
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :voyage_type_id, notify: [{ url: '/finished_goods/dispatch/voyages/voyage_type_changed' }]
      end
    end
  end
end
