# frozen_string_literal: true

module UiRules
  class ReworksRunPalletRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @repo = ProductionApp::ReworksRepo.new
      @setup_repo = ProductionApp::ProductSetupRepo.new

      make_form_object
      apply_form_values

      # @rules[:provide_pack_type] = AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION
      @rules[:provide_pack_type] = AppConst::CR_PROD.provide_pack_type_at_carton_verification?
      @rules[:carton_equals_pallet] = AppConst::CR_PROD.carton_equals_pallet?
      @rules[:show_shipping_details] = @form_object[:shipped]
      @rules[:has_individual_cartons] = @form_object[:has_individual_cartons]

      set_pallet_gross_weight_fields if @mode == :set_pallet_gross_weight
      set_edit_pallet_details_fields if @mode == :edit_pallet_details
      make_reworks_run_pallet_header_table if %i[edit_pallet].include? @mode
      set_select_pallet_sequence_fields if @mode == :select_pallet_sequence
      set_pallet_sequence_changes if @mode == :show_changes
      if @mode == :shipping
        make_reworks_run_pallet_header_table(%i[vessel voyage voyage_number container internal_container temp_code vehicle_number
                                                cooled pol pod region country final_destination customer consignee final_receiver
                                                exporter billing_client eta ata etd atd])
      end
      if @mode == :quantity
        make_reworks_run_pallet_header_table(%i[pallet_number farm orchard puc commodity cultivar marketing_variety
                                                grade pallet_size mark gross_weight nett_weight])
      end

      edit_pallet_details_behaviours if %i[edit_pallet_details].include? @mode

      form_name 'reworks_run_pallet'
    end

    def make_reworks_run_pallet_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[pallet_number production_run_id farm orchard puc commodity cultivar_group cultivar build_status
                                            pallet_size gross_weight nett_weight location pallet_base stack_type
                                            in_stock inspected reinspected palletized partially_palletized allocated
                                            pallet_age stock_age cold_age ambient_age inspection_age reinspection_age
                                            created_at stock_created_at first_cold_storage_at govt_first_inspection_at govt_reinspection_at
                                            palletized_at partially_palletized_at allocated_at gross_weight_measured_at],
                     display_columns: display_columns,
                     header_captions: {
                       first_cold_storage_at: 'Cold Storage Date',
                       govt_first_inspection_at: 'Inspection At',
                       govt_reinspection_at: 'Reinspection At',
                       marketing_variety: 'Variety'
                     })
    end

    def set_select_pallet_sequence_fields
      reworks_run_type_id_label = @repo.find_hash(:reworks_run_types, @options[:reworks_run_type_id])[:run_type]
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:pallet_sequence_id] = { renderer: :hidden }
      fields[:reworks_run_type] = { renderer: :label,
                                    with_value: reworks_run_type_id_label,
                                    caption: 'Reworks Run Type' }
      fields[:pallets_selected] = { renderer: :textarea,
                                    rows: 10,
                                    disabled: true,
                                    caption: 'Selected Pallet Numbers' }
      fields[:id] = { renderer: :lookup,
                      lookup_name: :pallet_sequences_for_reworks,
                      lookup_key: :standard,
                      param_values: { pallets_selected: @options[:pallets_selected].join(',') },
                      hidden_fields: %i[id],
                      show_field: :id,
                      caption: 'Representative sequence' }
    end

    def set_pallet_sequence_changes # rubocop:disable Metrics/AbcSize
      rules[:left_record] = sequence_setup_data(@options[:id])
      rules[:right_record] = sequence_edit_data(@options[:attrs])
      rules[:no_changes_made] = rules[:left_record] == rules[:right_record]
      fields[:changes_made] = {
        left_caption: 'Before',
        right_caption: 'After',
        left_record: rules[:left_record].sort.to_h,
        right_record: rules[:right_record].sort.to_h
      }
    end

    def set_pallet_gross_weight_fields
      fields[:pallet_number] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:standard_pack_code_id] = if rules[:provide_pack_type]
                                         { renderer: :select,
                                           options: @repo.for_select_standard_packs,
                                           disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_standard_packs,
                                           caption: 'Standard Pack',
                                           required: true,
                                           prompt: 'Select Standard Pack',
                                           searchable: true,
                                           remove_search_for_small_list: false }
                                       else
                                         { renderer: :hidden }
                                       end

      fields[:gross_weight] = { renderer: :numeric,
                                required: true,
                                maxvalue: AppConst::MAX_PALLET_WEIGHT }
    end

    def set_edit_pallet_details_fields # rubocop:disable Metrics/AbcSize
      requires_material_owner = @repo.pallet_requires_material_owner?(@form_object.pallet_number)
      fields[:pallet_number] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:fruit_sticker_pm_product_id] = { renderer: :select,
                                               options: MasterfilesApp::BomRepo.new.for_select_pm_products(
                                                 where: { subtype_code: AppConst::PM_SUBTYPE_FRUIT_STICKER }
                                               ),
                                               caption: 'Fruit Sticker',
                                               prompt: 'Select Fruit Sticker',
                                               searchable: true,
                                               remove_search_for_small_list: false }
      fields[:fruit_sticker_pm_product_2_id] = { renderer: :select,
                                                 options: MasterfilesApp::BomRepo.new.for_select_pm_products(
                                                   where: { subtype_code: AppConst::PM_SUBTYPE_FRUIT_STICKER }
                                                 ),
                                                 caption: 'Fruit Sticker 2',
                                                 prompt: 'Select Fruit Sticker 2',
                                                 searchable: true,
                                                 remove_search_for_small_list: false }
      fields[:batch_number] = { invisible: !AppConst::CR_PROD.capture_batch_number_for_pallets? }
      fields[:rmt_container_material_owner_id] = { renderer: :select,
                                                   options: @setup_repo.for_select_rmt_container_material_owners,
                                                   caption: 'Rmt Container Material Owner',
                                                   prompt: 'Select Rmt Container Material Owner',
                                                   searchable: true,
                                                   remove_search_for_small_list: false,
                                                   hide_on_load: !requires_material_owner }
    end

    def make_form_object # rubocop:disable Metrics/AbcSize
      if @mode == :show_changes
        @form_object = OpenStruct.new(id: @options[:id],
                                      params: @options[:attrs],
                                      pallet_sequence_id: @options[:id])
        return
      end

      if @mode == :select_pallet_sequence
        @form_object = OpenStruct.new(reworks_run_type_id: @options[:reworks_run_type_id],
                                      pallets_selected: resolve_selected_pallet_numbers(@options[:pallets_selected]),
                                      pallet_sequence_id: nil)
        return
      end

      if @mode == :set_pallet_gross_weight
        @form_object = OpenStruct.new(reworks_run_type_id: @options[:reworks_run_type_id],
                                      pallet_number: @options[:pallet_number],
                                      standard_pack_code_id: standard_pack_code(@options[:pallet_number]))
        return
      end

      @form_object = OpenStruct.new(reworks_run_pallet(@options[:pallet_number]).to_h.merge(reworks_run_type_id: @options[:reworks_run_type_id]))
    end

    def reworks_run_pallet(pallet_number)
      @repo.reworks_run_pallet_data(pallet_number)
    end

    def sequence_setup_data(id)
      @repo.sequence_setup_data(id)
    end

    def sequence_edit_data(attrs)
      @repo.sequence_edit_data(attrs)
    end

    def standard_pack_code(pallet_number)
      oldest_sequence_id = @repo.oldest_sequence_id(pallet_number)
      @repo.where_hash(:pallet_sequences, id: oldest_sequence_id)[:standard_pack_code_id]
    end

    private

    def edit_pallet_details_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :fruit_sticker_pm_product_id,
                                  notify: [{ url: "/production/reworks/pallets/#{@options[:pallet_number]}/fruit_sticker_changed" }]
      end
    end

    def resolve_selected_pallet_numbers(pallets_selected)
      return '' if pallets_selected.nil_or_empty?

      pallet_numbers = pallets_selected.join(',').split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = pallet_numbers.map { |x| x.gsub(/['"]/, '') }
      pallet_numbers.join("\n")
    end
  end
end
