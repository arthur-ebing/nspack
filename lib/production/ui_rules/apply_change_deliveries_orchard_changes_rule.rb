# frozen_string_literal: true

module UiRules
  class ApplyChangeDeliveriesOrchardChangesRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @reworks_repo = ProductionApp::ReworksRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new

      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'summary'
    end

    def common_fields  # rubocop:disable Metrics/AbcSize
      compact_header(columns: %i[deliveries production_runs tipped_bins carton_labels pallet_sequences
                                 shipped_pallet_sequences inspected_pallet_sequences],
                     display_columns: 2)

      from_ochard_code_label = @farm_repo.find_farm_orchard_by_orchard_id(@form_object[:from_orchard])
      from_cultivar = @form_object[:from_cultivar].nil_or_empty? ? nil : @form_object[:from_cultivar]
      affected_deliveries = @form_object[:affected_deliveries].split("\n").map(&:strip).reject(&:empty?)
      from_cultivar_name_label = if from_cultivar.nil_or_empty?
                                   @reworks_repo.find_from_deliveries_cultivar(affected_deliveries.join(',')).group_by { |h| h[:cultivar_name] }.keys.join(',')
                                 else
                                   @cultivar_repo.find_cultivar(from_cultivar)&.cultivar_name
                                 end
      to_ochard_code_label = @farm_repo.find_farm_orchard_by_orchard_id(@form_object[:to_orchard])
      to_cultivar_name_label = @cultivar_repo.find_cultivar(@form_object[:to_cultivar])&.cultivar_name
      @form_object[:allow_cultivar_mixing] = @form_object[:allow_cultivar_mixing] == 't'
      @form_object[:ignore_runs_that_allow_mixing] = @form_object[:ignore_runs_that_allow_mixing] == 't'
      {
        from_orchard: { renderer: :hidden,
                        value: @form_object[:from_orchard] },
        from_ochard_code: { renderer: :label,
                            with_value: from_ochard_code_label,
                            caption: 'From Orchard',
                            readonly: true },
        to_orchard: { renderer: :hidden,
                      value: @form_object[:to_orchard] },
        to_ochard_code: { renderer: :label,
                          with_value: to_ochard_code_label,
                          caption: 'To Orchard',
                          readonly: true },
        from_cultivar: { renderer: :hidden,
                         value: from_cultivar },
        from_cultivar_name: { renderer: :label,
                              with_value: from_cultivar_name_label,
                              caption: 'From Cultivar', readonly: true },
        to_cultivar: { renderer: :hidden,
                       value: @form_object[:to_cultivar] },
        to_cultivar_name: { renderer: :label,
                            with_value: to_cultivar_name_label,
                            caption: 'To Cultivar',
                            readonly: true },
        allow_cultivar_mixing: { renderer: :label,
                                 as_boolean: true },
        ignore_runs_that_allow_mixing: { renderer: :label,
                                         as_boolean: true },
        affected_deliveries: { renderer: :textarea,
                               rows: 15,
                               disabled: true,
                               caption: 'Deliveries' },
        spacer: { hide_on_load: true }
      }
    end

    def make_form_object  # rubocop:disable Metrics/AbcSize
      affected_deliveries = @options[:form_values][:affected_deliveries]
      allow_cultivar_mixing = @options[:form_values][:allow_cultivar_mixing] == 't'
      ignore_runs_that_allow_mixing = @options[:form_values][:ignore_runs_that_allow_mixing] == 't'
      deliveries_ids = affected_deliveries.split("\n").map(&:strip).reject(&:empty?)
      res = @reworks_repo.change_objects_counts(deliveries_ids, ignore_runs_that_allow_mixing)
      @form_object = OpenStruct.new(from_orchard: @options[:form_values][:from_orchard],
                                    to_orchard: @options[:form_values][:to_orchard],
                                    from_cultivar: @options[:form_values][:from_cultivar],
                                    to_cultivar: @options[:form_values][:to_cultivar],
                                    affected_deliveries: affected_deliveries,
                                    ignore_runs_that_allow_mixing: ignore_runs_that_allow_mixing,
                                    allow_cultivar_mixing: allow_cultivar_mixing,
                                    deliveries: res[:deliveries],
                                    production_runs: res[:production_runs],
                                    tipped_bins: res[:tipped_bins],
                                    carton_labels: res[:carton_labels],
                                    pallet_sequences: res[:pallet_sequences],
                                    shipped_pallet_sequences: res[:shipped_pallet_sequences],
                                    inspected_pallet_sequences: res[:inspected_pallet_sequences])
    end
  end
end
