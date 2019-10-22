# frozen_string_literal: true

module UiRules
  class VoyagePortRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::VoyagePortRepo.new
      make_form_object
      apply_form_values
      rules[:item_visibility] = item_visibility
      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      add_behaviours

      form_name 'voyage_port'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      voyage_id_label = @repo.find(:voyages, FinishedGoodsApp::Voyage, @form_object.voyage_id)&.voyage_number
      port_id_label = @repo.find(:ports, MasterfilesApp::Port, @form_object.port_id)&.port_code
      port_type_id_label = MasterfilesApp::PortRepo.new.find_port_flat(@form_object.port_id)&.port_type_code
      trans_shipment_vessel_id_label = @repo.find(:vessels, MasterfilesApp::Vessel, @form_object.trans_shipment_vessel_id)&.vessel_code
      fields[:voyage_id] = { renderer: :label, with_value: voyage_id_label, caption: 'Voyage' }
      fields[:port_id] = { renderer: :label, with_value: port_id_label, caption: 'Port' }
      fields[:port_type_id] = { renderer: :label, with_value: port_type_id_label, caption: 'Port type' }
      fields[:trans_shipment_vessel_id] = { renderer: :label, with_value: trans_shipment_vessel_id_label, caption: 'Trans shipment vessel' }
      fields[:ata] = { renderer: :label }
      fields[:atd] = { renderer: :label }
      fields[:eta] = { renderer: :label }
      fields[:etd] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      voyage_id = @options[:voyage_id].nil? ? @form_object.voyage_id : @options[:voyage_id]
      voyage_type_id = FinishedGoodsApp::VoyageRepo.new.find_voyage_flat(voyage_id)&.voyage_type_id
      {
        port_type_id: { renderer: :select,
                        options: MasterfilesApp::PortTypeRepo.new.for_select_port_types,
                        caption: 'Port type',
                        prompt: true,
                        required: true },
        voyage_id: { hide_on_load: true,
                     renderer: :select,
                     options: FinishedGoodsApp::VoyageRepo.new.for_select_voyages,
                     caption: 'Voyage',
                     required: true },
        port_id: { hide_on_load: rules[:item_visibility][:port_id],
                   renderer: :select,
                   options: MasterfilesApp::PortRepo.new.for_select_ports(voyage_type_id: voyage_type_id, port_type_id: @form_object.port_type_id),
                   caption: 'Port',
                   prompt: true,
                   required: true },
        trans_shipment_vessel_id: { hide_on_load: rules[:item_visibility][:trans_shipment_vessel_id],
                                    renderer: :select,
                                    options: MasterfilesApp::VesselRepo.new.for_select_vessels,
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
    end

    def make_new_form_object
      @form_object = OpenStruct.new(voyage_id: nil,
                                    port_type_id: nil,
                                    port_id: nil,
                                    trans_shipment_vessel_id: nil,
                                    ata: nil,
                                    atd: nil,
                                    eta: nil,
                                    etd: nil)
    end

    private

    def item_visibility
      vis = { port_id: true, trans_shipment_vessel_id: true, ata: true, atd: true, eta: true, etd: true }
      case MasterfilesApp::PortRepo.new.find_port_flat(@form_object.port_id)&.port_type_code
      when 'POL'
        vis[:port_id] = vis[:ata] = vis[:eta] = false
      when 'POD'
        vis[:port_id] = vis[:atd] = vis[:etd] = false
      when 'TRANSSHIP'
        vis[:port_id] = vis[:trans_shipment_vessel_id] = false
        vis[:ata] = vis[:eta] = vis[:atd] = vis[:etd] = false
      end
      vis
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :port_type_id, notify: [{ url: '/finished_goods/dispatch/voyage_ports/port_type_changed',
                                                            param_keys: %i[voyage_port_voyage_id] }]
      end
    end
  end
end
