# frozen_string_literal: true

module UiRules
  class VoyagePortRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = FinishedGoodsApp::VoyagePortRepo.new
      make_form_object
      apply_form_values
      add_rules
      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      add_behaviours

      form_name 'voyage_port'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:voyage_id] = { renderer: :label, with_value: @form_object&.voyage_number, caption: 'Voyage' }
      fields[:port_id] = { renderer: :label, with_value: @form_object&.port_code, caption: 'Port' }
      fields[:port_type_id] = { renderer: :label, with_value: @form_object.port_type_code, caption: 'Port type' }
      fields[:trans_shipment_vessel_id] = { renderer: :label,
                                            with_value: @form_object&.vessel_code,
                                            caption: 'Trans shipment vessel',
                                            hide_on_load: rules[:item_visibility][:trans_shipment_vessel_id] }
      fields[:ata] = { renderer: :label,
                       hide_on_load: rules[:item_visibility][:ata] }
      fields[:atd] = { renderer: :label,
                       hide_on_load: rules[:item_visibility][:atd] }
      fields[:eta] = { renderer: :label,
                       hide_on_load: rules[:item_visibility][:eta] }
      fields[:etd] = { renderer: :label,
                       hide_on_load: rules[:item_visibility][:etd] }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        port_type_id: { hide_on_load: @rules[:on_load],
                        renderer: :select,
                        options: MasterfilesApp::PortTypeRepo.new.for_select_port_types,
                        disabled_options: MasterfilesApp::PortTypeRepo.new.for_select_inactive_port_types,
                        caption: 'Port type',
                        prompt: true,
                        required: true },
        port_type_code: { renderer: :label,
                          with_value: @form_object&.port_type_code,
                          caption: 'Port type' },
        voyage_id: { hide_on_load: true,
                     renderer: :select,
                     options: FinishedGoodsApp::VoyageRepo.new.for_select_voyages,
                     disabled_options: FinishedGoodsApp::VoyageRepo.new.for_select_inactive_voyages,
                     caption: 'Voyage',
                     required: true },
        port_id: { hide_on_load: rules[:item_visibility][:port_id],
                   renderer: :select,
                   options: MasterfilesApp::PortRepo.new.for_select_ports(voyage_type_id: @form_object.voyage_type_id,
                                                                          port_type_id: @form_object.port_type_id),
                   disabled_options: MasterfilesApp::PortRepo.new.for_select_inactive_ports(voyage_type_id: @form_object.voyage_type_id,
                                                                                            port_type_id: @form_object.port_type_id),
                   caption: 'Port',
                   prompt: true,
                   required: true },
        trans_shipment_vessel_id: { hide_on_load: rules[:item_visibility][:trans_shipment_vessel_id],
                                    renderer: :select,
                                    options: MasterfilesApp::VesselRepo.new.for_select_vessels,
                                    disabled_options: MasterfilesApp::VesselRepo.new.for_select_inactive_vessels,
                                    prompt: '',
                                    caption: 'Trans shipment vessel' },
        eta: { renderer: :date,
               caption: 'ETA',
               hide_on_load: rules[:item_visibility][:eta] },
        ata: { renderer: :date,
               caption: 'ATA',
               hide_on_load: rules[:item_visibility][:ata] },
        etd: { renderer: :date,
               caption: 'ETD',
               hide_on_load: rules[:item_visibility][:etd] },
        atd: { renderer: :date,
               caption: 'ATD',
               hide_on_load: rules[:item_visibility][:atd] }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_voyage_port_flat(@options[:id])
      @rules[:on_load] = @repo.exists?(:loads, pol_voyage_port_id: @form_object.id) ||
                         @repo.exists?(:loads, pod_voyage_port_id: @form_object.id)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(voyage_id: @options[:voyage_id],
                                    voyage_type_id: @repo.get(:voyages, @options[:voyage_id], :voyage_type_id),
                                    port_id: nil,
                                    port_type_id: nil,
                                    trans_shipment_vessel_id: nil,
                                    ata: nil,
                                    atd: nil,
                                    eta: nil,
                                    etd: nil)
    end

    private

    def add_rules
      vis = { port_id: true, trans_shipment_vessel_id: true, ata: true, atd: true, eta: true, etd: true }
      case @repo.get(:port_types, @form_object.port_type_id, :port_type_code)
      when 'POL'
        vis[:port_id] = vis[:ata] = vis[:eta] = false
      when 'POD'
        vis[:port_id] = vis[:atd] = vis[:etd] = false
      when 'TRANSSHIP'
        vis[:port_id] = vis[:trans_shipment_vessel_id] = false
        vis[:ata] = vis[:eta] = vis[:atd] = vis[:etd] = false
      end
      rules[:item_visibility] = vis
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :port_type_id, notify: [{ url: '/finished_goods/dispatch/voyage_ports/port_type_changed',
                                                            param_keys: %i[voyage_type_id],
                                                            param_values: { voyage_type_id: @form_object.voyage_type_id } }]
      end
    end
  end
end
