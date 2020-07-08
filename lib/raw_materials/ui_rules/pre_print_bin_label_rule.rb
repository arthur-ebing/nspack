# frozen_string_literal: true

module UiRules
  class PrePrintBinLabelRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new

      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      add_behaviours if @mode == :new

      form_name 'rmt_delivery'
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      fields = {
        farm_id: { renderer: :select, options: MasterfilesApp::FarmRepo.new.for_select_farms, disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_farms, caption: 'Farm',
                   required: false, prompt: true },
        puc_id: { renderer: :select, options: [], caption: 'Puc', required: false, prompt: true },
        orchard_id: { renderer: :select, options: [], caption: 'Orchard', required: false, prompt: true  },
        cultivar_id: { renderer: :select, options: [], caption: 'Cultivar', required: false, prompt: true },
        no_of_prints: { required: true },
        printer: { renderer: :select, options: LabelApp::PrinterRepo.new.select_printers_for_application(AppConst::PRINT_APP_BIN), required: false, prompt: true },
        bin_label: { renderer: :select, options: LabelApp::PrinterRepo.new.find_bin_labels, required: false, prompt: true }
      }

      fields[:puc_id][:options] = RawMaterialsApp::RmtDeliveryRepo.new.farm_pucs(@form_object.farm_id) unless @form_object.farm_id.nil_or_empty?
      fields[:orchard_id][:options] = RawMaterialsApp::RmtDeliveryRepo.new.orchards(@form_object.farm_id, @form_object.puc_id) unless @form_object.puc_id.nil_or_empty?
      fields[:cultivar_id][:options] = RawMaterialsApp::RmtDeliveryRepo.new.orchard_cultivars(@form_object.orchard_id) unless @form_object.orchard_id.nil_or_empty?
      fields
    end

    def make_form_object
      @form_object = OpenStruct.new
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id, notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/farm_combo_changed' }]
        behaviour.dropdown_change :puc_id, notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/puc_combo_changed', param_keys: %i[rmt_delivery_farm_id rmt_delivery_puc_id] }]
        behaviour.dropdown_change :orchard_id, notify: [{ url: '/raw_materials/deliveries/preprint_orchard_combo_changed', param_keys: %i[rmt_delivery_orchard_id] }]
      end
    end
  end
end
