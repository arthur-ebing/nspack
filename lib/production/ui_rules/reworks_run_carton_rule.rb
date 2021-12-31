# frozen_string_literal: true

module UiRules
  class ReworksRunCartonRule < Base
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      @mesc_repo = MesscadaApp::MesscadaRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      make_header_table  if @mode == :clone_carton
      make_header_table(%i[pallet_number pallet_sequence_number], 1) if @mode == :manage

      form_name 'reworks_run_carton'
    end

    def common_fields
      max_no_of_clones = AppConst::ALLOW_OVERFULL_REWORKS_PALLETIZING ? nil : @form_object[:no_of_clones]
      {
        carton_id: { renderer: :hidden },
        pallet_id: { renderer: :hidden },
        pallet_sequence_id: { renderer: :hidden },
        no_of_clones: { renderer: :integer,
                        required: true,
                        maxvalue: max_no_of_clones }
      }
    end

    def make_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[inventory_code target_market_group_name target_market_name grade_code mark_code size_reference
                                            standard_pack_code size_count_value cultivar_name cultivar_group_code],
                     display_columns: display_columns,
                     header_captions: {
                       pallet_number: 'Pallet Number',
                       pallet_sequence_number: 'Seq Number',
                       inventory_code: 'Inventory',
                       target_market_group_name: 'TM Group',
                       target_market_name: 'Target Market',
                       grade_code: 'Grade',
                       mark_code: 'Mark',
                       size_reference: 'Size Ref',
                       standard_pack_code: 'Standard Pack',
                       size_count_value: 'Size Count',
                       cultivar_group_code: 'Cultivar Group',
                       cultivar_name: 'Cultivar'
                     })
    end

    def make_form_object # rubocop:disable Metrics/AbcSize
      if @mode == :manage
        sequence = find_sequence(@options[:id])
        @form_object = OpenStruct.new(pallet_sequence_id: @options[:id],
                                      pallet_number: sequence[:pallet_number],
                                      pallet_sequence_number: sequence[:pallet_sequence_number])
        return
      end

      carton = find_carton(@options[:id])
      pallet_id = sequence_pallet_id(carton[:pallet_sequence_id])
      oldest_sequence_id = oldest_sequence_id(sequence_pallet_number(carton[:pallet_sequence_id]))
      cartons_per_pallet_id = pallet_sequence_cartons_per_pallet_id(oldest_sequence_id)
      @form_object = @mesc_repo.carton_attributes(carton[:id]).to_h.merge(carton_id: carton[:id],
                                                                          pallet_id: pallet_id,
                                                                          pallet_sequence_id: carton[:pallet_sequence_id],
                                                                          no_of_clones: default_no_of_clones(cartons_per_pallet_id, pallet_id))
    end

    def find_sequence(sequence_id)
      @repo.where(:pallet_sequences, MesscadaApp::PalletSequence, id: sequence_id)
    end

    def find_carton(carton_id)
      @repo.where(:cartons, MesscadaApp::Carton, id: carton_id)
    end

    def sequence_pallet_id(pallet_sequence_id)
      @repo.get(:pallet_sequences, :pallet_id, pallet_sequence_id)
    end

    def sequence_pallet_number(pallet_sequence_id)
      @repo.get(:pallet_sequences, :pallet_number, pallet_sequence_id)
    end

    def oldest_sequence_id(pallet_number)
      @repo.oldest_sequence_id(pallet_number)
    end

    def pallet_sequence_cartons_per_pallet_id(pallet_sequence_id)
      @repo.get(:pallet_sequences, :cartons_per_pallet_id, pallet_sequence_id)
    end

    def default_no_of_clones(cartons_per_pallet_id, pallet_id)
      (@repo.get(:cartons_per_pallet, :cartons_per_pallet, cartons_per_pallet_id).to_i - @repo.get(:pallets, :carton_quantity, pallet_id).to_i)
    end
  end
end
