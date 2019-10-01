# frozen_string_literal: true

module UiRules
  class VoyagePortRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::VoyagePortRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'voyage_port'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      voyage_id_label = @repo.find(:voyages, FinishedGoodsApp::Voyage, @form_object.voyage_id)&.voyage_number
      port_id_label = @repo.find(:ports, MasterfilesApp::Port, @form_object.port_id)&.port_code
      trans_shipment_vessel_id_label = @repo.find(:vessels, MasterfilesApp::Vessel, @form_object.trans_shipment_vessel_id)&.vessel_code
      fields[:voyage_id] = { renderer: :label, with_value: voyage_id_label, caption: 'Voyage' }
      fields[:port_id] = { renderer: :label, with_value: port_id_label, caption: 'Port' }
      fields[:trans_shipment_vessel_id] = { renderer: :label, with_value: trans_shipment_vessel_id_label, caption: 'Trans Shipment Vessel' }
      fields[:ata] = { renderer: :label }
      fields[:atd] = { renderer: :label }
      fields[:eta] = { renderer: :label }
      fields[:etd] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        voyage_id: { renderer: :select, options: FinishedGoodsApp::VoyageRepo.new.for_select_voyages, disabled_options: FinishedGoodsApp::VoyageRepo.new.for_select_inactive_voyages, caption: 'Voyage', required: true },
        port_id: { renderer: :select, options: MasterfilesApp::PortRepo.new.for_select_ports, disabled_options: MasterfilesApp::PortRepo.new.for_select_inactive_ports, caption: 'Port', required: true },
        trans_shipment_vessel_id: { renderer: :select, options: MasterfilesApp::VesselRepo.new.for_select_vessels, disabled_options: MasterfilesApp::VesselRepo.new.for_select_inactive_vessels, caption: 'Trans Shipment Vessel' },
        ata: { renderer: :datetime },
        atd: { renderer: :datetime },
        eta: { renderer: :datetime },
        etd: { renderer: :datetime }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_voyage_port(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(voyage_id: nil,
                                    port_id: nil,
                                    trans_shipment_vessel_id: nil,
                                    ata: nil,
                                    atd: nil,
                                    eta: nil,
                                    etd: nil)
    end
  end
end
