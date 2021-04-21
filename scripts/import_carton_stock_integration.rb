# frozen_string_literal: true

require_relative '../app_loader'

# Reason for this script:
# -----------------------
# For deployment at Kromco
# Import legacy pallet and carton data.
# The pallet sequences and carton labels require a production run. Please create a run to run this script against.
# DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ImportCartonStockIntegration 'file_name.csv' production_run_id

class ImportCartonStockIntegration < BaseScript # rubocop:disable Metrics/ClassLength
  def run # rubocop:disable Metrics/AbcSize
    @filename = args[0]
    @production_run_id = args[1]
    @status = 'IMPORTED_FOR_GO_LIVE'
    @repo = BaseRepo.new
    @errors = []
    @pallet_ids_created = []
    @pallet_sequence_ids_created = []

    DB.transaction do
      parse_csv
      infodump
      if @errors.empty?
        puts 'Import Completed'
        raise Crossbeams::InfoError, 'Debug mode: Import Completed' if debug_mode

        success_response('Import Completed')
      else
        puts 'Import failed'
        @errors.uniq.each { |error| p error }
        raise Crossbeams::InfoError, 'Import failed'
      end
    end
  end

  private

  def parse_csv # rubocop:disable Metrics/AbcSize
    table = CSV::Table.new(CSV.parse(File.read(@filename), headers: true).sort_by { |row| row['pallet_number'] }.sort_by { |row| row['pallet_sequence_number'] })

    @previous_errors = []
    table['pallet_number'].uniq.sort.each do |pallet_number|
      pallet_rows = table.select { |row| row['pallet_number'] == pallet_number }
      res = process_pallet(pallet_rows)
      puts res.message
    end
  end

  def process_pallet(pallet_rows) # rubocop:disable Metrics/AbcSize
    res = nil
    params = get_mf_ids_for_pallet(pallet_rows.first.to_h)
    unless @errors.empty?
      print_error(params[:pallet_number])
      res = failed_response("failed to create pallet: #{params[:pallet_number]}")
    end
    params[:pallet_id] = create_pallet(params)
    pallet_rows.each_with_index do |sequence, index|
      pallet_sequence_number = index + 1
      params.merge!(sequence)
      params[:pallet_sequence_number] = pallet_sequence_number
      params = get_mf_ids_for_pallet_sequence(params)
      unless @errors.empty?
        print_error(params[:pallet_number])
        res = failed_response("failed to create pallet sequence: #{params[:pallet_number]}_#{pallet_sequence_number}")
      end

      params[:pallet_sequence_id] = create_pallet_sequence(params)
      carton_numbers = params[:carton_numbers].split('|')
      carton_numbers.each do |carton_number|
        params.merge!(legacy_carton_number: carton_number)

        params[:carton_label_id] = create_carton_label(params)
        create_carton(params)
      end
    end
    return res if res

    success_response("Created Pallet:#{params[:pallet_number]}")
  rescue Crossbeams::InfoError => e
    print_error(params[:pallet_number])
    failed_response(e)
  end

  def print_error(pallet_number)
    new_errors = @errors.uniq - @previous_errors
    unless new_errors.empty?
      puts pallet_number
      new_errors.uniq.each { |error| puts error }
      puts ''
    end
    @previous_errors = @errors.uniq
  end

  def get_mf_ids_for_pallet_sequence(hash) # rubocop:disable Metrics/AbcSize
    @errors = []
    hash[:legacy_data] = { extended_fg_code: hash.delete(:extended_fg_code),
                           extended_fg_id: hash.delete(:extended_fg_id),
                           bin_id: hash.delete(:bin_id),
                           pallet_id: hash.delete(:legacy_pallet_id),
                           production_run_id: hash.delete(:production_run_id) }

    args = OpenStruct.new(hash)
    args.production_run_id = @production_run_id

    args.farm_id = get_id_or_error(:farms, farm_code: args.farm_code)
    args.puc_id = get_id_or_error(:pucs, puc_code: args.puc_code)
    args.orchard_id = get_id_or_error(:orchards,
                                      orchard_code: args.orchard_code,
                                      puc_id: args.puc_id,
                                      farm_id: args.farm_id)

    args.cultivar_code = args.rmt_variety
    args.cultivar_id = get_id_or_error(:cultivars,
                                       cultivar_name: args.rmt_variety,
                                       commodity_id: args.commodity_id)

    args.cultivar_group_id = @repo.get(:cultivars, args.cultivar_id, :cultivar_group_id)

    args.product_resource_allocation_id = nil

    organization_id = get_id_or_error(:organizations, short_description: args.marketing_org)
    role_id = get_id_or_error(:roles, name: AppConst::ROLE_MARKETER)
    args.marketing_org_party_role_id = get_id_or_error(:party_roles,
                                                       organization_id: organization_id,
                                                       role_id: role_id)
    @errors << "marketing_org_party_role_id masterfile not found, for #{args.marketing_org}" unless args.marketing_org_party_role_id

    args.marketing_orchard_id = create_registered_orchard(args.to_h)
    args.marketing_puc_id = get_id_or_error(:pucs, puc_code: args.marketing_puc)
    args.marketing_variety_id = get_id_or_error(:marketing_varieties,
                                                marketing_variety_code: args.marketing_variety)

    args.destination_region_id = get_id_or_error(:destination_regions, destination_region_name: args.packed_tm_group)
    args.packed_tm_group_id = DB[:destination_regions_tm_groups]
                              .where(destination_region_id: args.destination_region_id)
                              .get(:target_market_group_id)
    @errors << "destination_regions_tm_groups masterfile not found, args: destination_region_id: #{args.destination_region_id} for packed_tm_group_id" unless args.packed_tm_group_id

    args.target_market_id = DB[:target_markets_for_groups].where(target_market_group_id: args.packed_tm_group_id).get(:target_market_id)
    @errors << "target_markets_for_groups masterfile not found, args: target_market_group_id: #{args.packed_tm_group_id} for target_market_id" unless args.target_market_id

    unless args.target_customer.nil_or_empty?
      organization_id = get_id_or_error(:organizations, short_description: args.target_customer)
      role_id = get_id_or_error(:roles, name: AppConst::ROLE_TARGET_CUSTOMER)
      args.target_customer_party_role_id = get_id_or_error(:party_roles,
                                                           organization_id: organization_id,
                                                           role_id: role_id)
      @errors << "target_customer_party_role_id masterfile not found, for #{args.target_customer}" unless args.target_customer_party_role_id
    end

    args.basic_pack_code_id = get_id_or_error(:basic_pack_codes,
                                              footprint_code: args.basic_pack_code,
                                              height_mm: args.carton_pack_height)
    args.standard_pack_code_id = get_id_or_error(:standard_pack_codes,
                                                 standard_pack_code: args.standard_pack_code)

    args.fruit_size_reference_id = get_id_or_error(:fruit_size_references,
                                                   size_reference: args.size_reference)
    args.std_fruit_size_count_id = get_id_or_error(:std_fruit_size_counts,
                                                   size_count_value: args.standard_count,
                                                   commodity_id: args.commodity_id)
    args.fruit_actual_counts_for_pack_id = get_id_or_error(:fruit_actual_counts_for_packs,
                                                           actual_count_for_pack: args.actual_count,
                                                           std_fruit_size_count_id: args.std_fruit_size_count_id,
                                                           basic_pack_code_id: args.basic_pack_code_id)

    args.mark_id = get_id_or_error(:marks, mark_code: args.mark)
    args.inventory_code_id = get_id_or_error(:inventory_codes, inventory_code: args.inventory_code)
    args.cartons_per_pallet_id = get_id_or_error(:cartons_per_pallet,
                                                 pallet_format_id: args.pallet_format_id,
                                                 basic_pack_id: args.basic_pack_code_id)
    args.scanned_from_carton_id = nil
    args.grade_id = get_id_or_error(:grades, grade_code: args.grade)

    args.pm_bom_id = get_pm_bom_id(args)
    args.pm_mark_id = get_pm_mark_id(args)

    args.verified = true
    args.verified_at = args.palletized_at
    args.verification_passed = true
    args.verification_result = 'PASSED'

    args.gtin_code = args.gtin
    args.rmt_class_id = get_id_or_error(:rmt_classes, rmt_class_code: args.product_class_code)

    args.packhouse_resource_id = get_id_or_error(:plant_resources, plant_resource_code: args.packhouse_code)
    args.production_line_id = get_id_or_error(:plant_resources, plant_resource_code: args.production_line_code)

    args.pallet_label_name = nil
    args.packing_method_id = get_id_or_error(:packing_methods, packing_method_code: 'NORMAL')
    args.product_chars = nil

    args.to_h
  end

  def get_pm_bom_id(args) # rubocop:disable Metrics/AbcSize
    level_1_product_code = "#{args.carton_pack_type}#{args.basic_pack_code}#{args.carton_pack_height}#{args.carton_pack_style}"
    level_3_product_code = "#{args.commodity_code}#{args.standard_count}"
    composition_level_1_id = get_id_or_error(:pm_products, product_code: level_1_product_code)
    composition_level_2_id = get_id_or_error(:pm_products, product_code: args.unit_pack_product)
    composition_level_3_id = get_id_or_error(:pm_products, product_code: level_3_product_code)
    composition_level_1_ = DB[:pm_boms_products].where(pm_product_id: composition_level_1_id).select_map(:pm_bom_id)
    composition_level_2_ = DB[:pm_boms_products].where(pm_product_id: composition_level_2_id).select_map(:pm_bom_id)
    composition_level_3_ = DB[:pm_boms_products].where(pm_product_id: composition_level_3_id).select_map(:pm_bom_id)
    pm_bom_ids = composition_level_1_ & composition_level_2_ & composition_level_3_
    # @errors << "pm_bom_id masterfile not found: pallet_number: #{args.pallet_number}" unless pm_bom_ids.length == 1
    pm_bom_ids.first
  end

  def get_pm_mark_id(args) # rubocop:disable Metrics/AbcSize
    mark_id = get_id_or_error(:marks, mark_code: args.brand)
    tu_id = get_id_or_error(:inner_pm_marks, inner_pm_mark_code: args.tu_mark, tu_mark: true)
    tu = @repo.get(:inner_pm_marks, tu_id, :inner_pm_mark_code) || args.tu_mark
    ru_id = get_id_or_error(:inner_pm_marks, inner_pm_mark_code: args.ru_mark, ru_mark: true)
    ru = @repo.get(:inner_pm_marks, ru_id, :inner_pm_mark_code) || args.ru_mark
    ri_id = get_id_or_error(:inner_pm_marks, inner_pm_mark_code: args.ri_item_mark, ri_mark: true)
    ri = @repo.get(:inner_pm_marks, ri_id, :inner_pm_mark_code) || args.ri_item_mark
    get_id_or_error(:pm_marks,
                    mark_id: mark_id,
                    packaging_marks: "{#{tu},#{ru},#{ri}}")
  end

  def get_mf_ids_for_pallet(hash) # rubocop:disable Metrics/AbcSize
    @errors = []
    hash[:legacy_data] = { pallet_id: hash['legacy_pallet_id'],
                           load_id: hash.delete('load_id'),
                           inspection_pallet_number: hash.delete('inspection_pallet_number'),
                           load_order_id: hash.delete('load_order_id') }

    args = OpenStruct.new(hash)
    args.commodity_code = args.extended_fg_code.slice(0..1)
    args.commodity_id = get_id_or_error(:commodities, code: args.commodity_code)
    args.season_id = get_id_or_error(:seasons,
                                     season_year: args.season,
                                     commodity_id: args.commodity_id)

    args.location_id = get_id_or_error(:locations, location_long_code: args.location_code)
    args.fruit_sticker_pm_product_id = nil
    args.pallet_base_id = get_id_or_error(:pallet_bases, pallet_base_code: args.pallet_base_code)
    args.pallet_stack_type_id = get_id_or_error(:pallet_stack_types, stack_type_code: args.stack_type)
    args.pallet_format_id = get_id_or_error(:pallet_formats,
                                            pallet_base_id: args.pallet_base_id,
                                            pallet_stack_type_id: args.pallet_stack_type_id)
    args.plt_packhouse_resource_id = get_id_or_error(:plant_resources, plant_resource_code: args.packhouse_code)
    args.plt_line_resource_id = get_id_or_error(:plant_resources, plant_resource_code: args.production_line_code)

    args.in_stock = args.inspection_result.to_s.upcase == 'PASSED'
    args.govt_first_inspection_at = args.inspected_at
    args.stock_created_at = args.intake_date
    args.intake_created_at = args.intake_date
    args.first_cold_storage_at = args.cold_date
    args.palletized = true
    @errors << "build_status is not FULL or PARTIAL, given value: #{args.build_status}" unless %w[FULL PARTIAL].include? args.build_status.to_s.upcase
    args.partially_palletized = args.build_status.to_s.upcase != 'FULL'
    if args.partially_palletized
      args.partially_palletized_at = args.palletized_at
      args.palletized_at = nil
    else
      args.partially_palletized_at = nil
    end
    args.allocated = false
    args.reinspected = false
    args.scrapped = false
    args.cooled = !args.cold_date.nil_or_empty?
    args.depot_pallet = args.is_depot_pallet == 't'
    args.edi_in_consignment_note_number = args.consignment_note_number
    args.edi_in_inspection_point = args.inspection_point

    args.to_h
  end

  def create_registered_orchard(params)
    existing_id = @repo.get_id(:registered_orchards, cultivar_code: params[:cultivar_code], puc_code: params[:puc_code])
    return existing_id if existing_id

    params[:marketing_orchard] = true
    params[:description] = nil
    res = MasterfilesApp::RegisteredOrchardSchema.call(params)
    raise Crossbeams::InfoError, "can't create_registered_orchard #{validation_failed_response(res).errors}" if res.failure?

    @repo.create(:registered_orchards, res.to_h)
  end

  def create_carton_label(params)
    res = MesscadaApp::CartonLabelContract.new.call(params)
    return "can't create_carton_label #{validation_failed_response(res).errors}" if res.failure?

    id = @repo.create(:carton_labels, res.to_h)
    log_status(:carton_labels, id, @status)

    @repo.create(:legacy_barcodes, carton_label_id: id, legacy_carton_number: params[:legacy_carton_number])
    id
  end

  def create_carton(params)
    res = MesscadaApp::CartonSchema.call(params)
    return "can't create_carton #{validation_failed_response(res).errors}" if res.failure?

    id = @repo.create(:cartons, res.to_h)
    log_status(:cartons, id, @status)

    id
  end

  def create_pallet_sequence(params)
    res = MesscadaApp::PalletSequenceContract.new.call(params)
    return "can't create_pallet_sequence #{validation_failed_response(res).errors}" if res.failure?

    id = @repo.create(:pallet_sequences, res.to_h)
    log_status(:pallet_sequences, id, @status)
    @pallet_sequence_ids_created << id
    id
  end

  def create_pallet(params)
    res = MesscadaApp::PalletContract.new.call(params)
    return "can't create_pallet #{validation_failed_response(res).errors}" if res.failure?

    id = @repo.create(:pallets, res.to_h)
    log_status(:pallets, id, @status)
    @pallet_ids_created << id
    id
  end

  def get_id_or_error(table_name, args)
    id = get_variant_id(table_name, args)
    @errors << "#{table_name} masterfile not found, args:#{args}" unless id

    id
  end

  def lookup_mf_variant(table_name)
    return {} if table_name.to_s.nil_or_empty?

    variant = AppConst::MF_VARIANT_RULES.select { |_, hash| hash.key(table_name.to_s) }
    return {} if variant.values.empty?

    { variant: variant.keys.first.to_s.gsub('_', ' '),
      table_name: table_name,
      column_name: variant.values.first[:column_name] }
  end

  def get_variant_id(table_name, args) # rubocop:disable Metrics/AbcSize
    params = args.clone
    id = @repo.get_id(table_name, params)
    return id unless id.nil?

    variant_column = lookup_mf_variant(table_name)[:column_name]
    return nil if variant_column.nil?

    variant_code = params.delete(variant_column.to_sym)
    id = DB[:masterfile_variants].where(masterfile_table: table_name.to_s, variant_code: variant_code).get(:masterfile_id)
    return nil if id.nil?

    @repo.get_id(table_name, params.merge(id: id))
  end

  def infodump
    infodump = <<~STR
      Script: ImportRmtDeliveriesBinsKr

      Reason for this script:
      -----------------------
      For deployment at Kromco
      Import legacy pallet and carton data.

      Results:
      --------
      errors:
      #{@errors.uniq.join("\n")}

      output:
      pallet_ids_created = #{@pallet_ids_created}
      pallet_sequence_ids_created = #{@pallet_sequence_ids_created}

      data:
      #{CSV.parse(File.read(@filename), headers: true)}
    STR
    log_infodump(:data_import,
                 :carton_stock_integration,
                 :go_live,
                 infodump)
  end
end
