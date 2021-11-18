# frozen_string_literal: true

module EdiApp
  class PoIn < BaseEdiInService # rubocop:disable Metrics/ClassLength
    attr_reader :org_code, :po_repo, :tot_cartons, :records

    def initialize(edi_in_transaction_id, file_path, logger, edi_result)
      @po_repo = PoInRepo.new
      super(edi_in_transaction_id, file_path, logger, edi_result)
    end

    def call # rubocop:disable Metrics/AbcSize
      # p "Got: #{edi_records.length} recs"
      log "Got: #{edi_records.length} recs"
      subset = edi_records.select { |rec| rec[:record_type].to_s == 'OP' }.group_by { |rec| rec[:sscc] }
      # p subset.length
      missing_required_fields(only_rows: 'OP')
      @records = {}
      subset.each do |pallet_number, sequences|
        @tot_cartons = sum_cartons(sequences)
        build_pallet(pallet_number, sequences.first)
        sequences.each do |sequence|
          build_sequence(pallet_number, sequence)
        end
      end
      create_missing_masterfiles if AppConst::EDI_AUTO_CREATE_MF

      mf_res = check_missing_mf
      unless mf_res.success
        missing_masterfiles_detected(mf_res.instance)
        return mf_res
      end

      business_validation_passed

      create_po_records
      success_response('PO processed')
    end

    private

    def create_po_records # rubocop:disable Metrics/AbcSize
      po_repo.transaction do
        records.each do |_, pallet|
          attrs = pallet[:record]
          pallet[:lookup_data].each do |field, val|
            next if %i[standard_pack_code_id basic_pack_code_id cartons_per_pallet_id fruit_size_reference_id].include?(field)

            attrs[field] = val
          end
          # p '>>> PALLET'
          # p attrs
          # validate attrs: PalletPoInSchema
          pallet_id = po_repo.create_pallet(attrs)

          pallet[:sub_records].each do |rec|
            seq_attrs = rec[:record]
            seq_attrs[:pallet_id] = pallet_id
            pallet[:lookup_data].each do |field, val|
              next unless %i[standard_pack_code_id basic_pack_code_id cartons_per_pallet_id fruit_size_reference_id pallet_format_id].include?(field)

              seq_attrs[field] = val
            end
            rec[:lookup_data].each do |field, val|
              seq_attrs[field] = val
            end
            # p '>>> SEQUENCE'
            # p seq_attrs
            # validate attrs: PalletSequencePoInSchema
            po_repo.create_pallet_sequence(seq_attrs)
          end
        end
      end
    end

    def create_missing_masterfiles
      progress = {}
      records.each do |_, pallet|
        pallet[:missing_mf].each do |code, rule|
          next if rule[:raise]

          if progress[rule]
            id = progress[rule]
          else
            # add rec..
            id = 123 # new val
            progress[rule] = id
          end
          pallet[:lookup_data][code] = id
          # also sub_records with the same code in lookup_data...
        end

        pallet[:sub_records].each do |rec|
          rec[:missing_mf].each do |code, rule|
            next if rule[:raise]

            p code
            # as above...
          end
        end
      end
    end

    def check_missing_mf # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      auto_create = AppConst::EDI_AUTO_CREATE_MF
      errs = []
      messages = []
      records.each do |_, pallet|
        pallet[:missing_mf].each do |code, rule|
          errs << "Missing masterfile - #{code}, #{rule[:keys].inspect}" if rule[:raise] || !auto_create
          messages << rule[:msg] || errs.last if rule[:raise] || !auto_create
        end

        pallet[:sub_records].each do |rec|
          rec[:missing_mf].each do |code, rule|
            errs << "Missing masterfile - #{code}, #{rule[:keys].inspect}" if rule[:raise] || !auto_create
            messages << rule[:msg] || errs.last if rule[:raise] || !auto_create
          end
        end
      end

      if messages.empty?
        ok_response
      else
        note = <<~STR
          Please add the missing masterfiles or create variants for them if applicable.

          Then go to #{AppConst::URL_BASE.chomp('/')}/edi/viewer/received/errors
          Select the line for file #{file_name} and click on "re-process this file" to retry this process.
        STR
        # failed_response('Missing masterfiles', "\n#{messages.uniq.join("\n")}\n\n#{note}\n#{errs.uniq.join("\n").gsub('{', '(').gsub('}', ')')}")
        failed_response('Missing masterfiles', "\n#{messages.uniq.join("\n")}\n\n#{note}")
      end
    end

    def sum_cartons(sequences)
      sequences.map { |seq| seq[:ctn_qty].to_i }.sum
    end

    def time_from_date_val(val)
      return nil if val.nil?

      Time.new(val[0, 4], val[4, 2], val[6, 3])
    end

    def time_from_date_and_time(date, time)
      return nil if date.nil? || time.nil?

      Time.new(date[0, 4], date[4, 2], date[6, 3], *time.split(':'))
    end

    def build_pallet(pallet_number, seq) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      location_id = MasterfilesApp::LocationRepo.new.location_id_from_short_code(AppConst::CR_EDI.install_location)
      raise Crossbeams::InfoError, "There is no INSTALL location named #{AppConst::CR_EDI.install_location}" if location_id.nil?

      records[pallet_number] = {
        lookup_data: {},  # data looked up from masterfiles.
        missing_mf: {},   # details about failed lookups
        missing_data: {}, # non-lookup data that should be in the file but is not.
        record: {},       # data that maps directly from the file
        sub_records: []   # pallet sequences
      }
      rec = records[pallet_number]
      orig_inspec_date = time_from_date_val(seq[:orig_inspec_date])
      inspec_date = time_from_date_val(seq[:inspec_date])
      intake_date = time_from_date_val(seq[:intake_date])
      weighed_date = time_from_date_and_time(seq[:weighing_date], seq[:weighing_time])
      reinspect_at = orig_inspec_date != inspec_date && !inspec_date.nil? ? inspec_date : nil

      standard_pack_code_id = po_repo.find_standard_pack_id(seq[:pack])
      rec[:lookup_data][:standard_pack_code_id] = standard_pack_code_id
      rec[:missing_mf][:standard_pack_code_id] = { mode: :direct, raise: false, keys: { pack: seq[:pack] }, msg: "Standard Pack: #{seq[:pack]}" } if standard_pack_code_id.nil?

      fruit_size_reference_id = po_repo.find_fruit_size_reference_id(seq[:size_count])
      rec[:lookup_data][:fruit_size_reference_id] = fruit_size_reference_id
      rec[:missing_mf][:fruit_size_reference_id] = { mode: :direct, raise: false, keys: { size_count: seq[:size_count] }, msg: "Size reference: #{seq[:size_count]}" } if fruit_size_reference_id.nil?

      basic_pack_code_id = po_repo.find_basic_pack_id(standard_pack_code_id)
      rec[:lookup_data][:basic_pack_code_id] = basic_pack_code_id
      rec[:missing_mf][:basic_pack_code_id] = { mode: :direct, raise: false, keys: { pack: seq[:pack] }, msg: "Basic pack: #{seq[:pack]}" } if basic_pack_code_id.nil?

      pallet_format_id, cartons_per_pallet_id = po_repo.find_pallet_format_and_cpp_id(seq[:pallet_btype], tot_cartons, basic_pack_code_id)
      rec[:lookup_data][:pallet_format_id] = pallet_format_id
      rec[:missing_mf][:pallet_format_id] = { mode: :direct, raise: true, keys: { pallet_btype: seq[:pallet_btype], cartons: tot_cartons, basic_pack_code_id: basic_pack_code_id }, msg: "Pallet format for pallet base: #{seq[:pallet_btype]}"  } if pallet_format_id.nil?
      rec[:lookup_data][:cartons_per_pallet_id] = cartons_per_pallet_id
      rec[:missing_mf][:cartons_per_pallet_id] = { mode: :direct, raise: true, keys: { pallet_btype: seq[:pallet_btype], cartons: tot_cartons, basic_pack_code_id: basic_pack_code_id }, msg: "Cartons Per Pallet for pallet #{pallet_number}, pallet base: #{seq[:pallet_btype]}, pack: #{seq[:pack]} and CCP: #{tot_cartons}" } if cartons_per_pallet_id.nil?

      gross_weight = if AppConst::CR_PROD.derive_nett_weight?
                       nil
                     else
                       seq[:pallet_gross_mass].nil? || seq[:pallet_gross_mass].to_f.zero? ? nil : seq[:pallet_gross_mass]
                     end
      # pallet_format_id: 0, # lookup
      rec[:record] = {
        depot_pallet: true,
        edi_in_consignment_note_number: seq[:orig_cons], # orig_cons is the consignment number
        edi_in_load_number: seq[:cons_no],               # cons_no   is the load number
        edi_in_transaction_id: edi_in_transaction.id,
        pallet_number: pallet_number,
        location_id: location_id,
        in_stock: true,
        inspected: !orig_inspec_date.nil? || !inspec_date.nil?,
        govt_first_inspection_at: orig_inspec_date || inspec_date,
        govt_reinspection_at: reinspect_at,
        stock_created_at: intake_date || inspec_date || Time.now,
        phc: seq[:packh_code] || AppConst::CR_EDI.edi_in_default_phc,
        intake_created_at: intake_date,
        gross_weight: gross_weight,
        gross_weight_measured_at: AppConst::CR_PROD.derive_nett_weight ? nil : weighed_date,
        derived_weight: AppConst::CR_PROD.derive_nett_weight?,
        palletized: true,
        palletized_at: intake_date,
        created_at: intake_date,
        reinspected: !reinspect_at.nil?,
        govt_inspection_passed: !orig_inspec_date.nil? || !inspec_date.nil?,
        temp_tail: seq[:temp_device_id],
        edi_in_inspection_point: seq[:inspect_pnt]
      }
    end

    def build_sequence(pallet_number, seq) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      rec = {
        lookup_data: {},  # data looked up from masterfiles.
        missing_mf: {},   # details about failed lookups
        missing_data: {}, # non-lookup data that should be in the file but is not.
        record: {}        # data that maps directly from the file
      }

      parent = records[pallet_number]

      inspec_date = time_from_date_val(seq[:inspec_date])
      tran_date = time_from_date_val(seq[:tran_date])

      puc_id = po_repo.find_puc_id(seq[:farm])
      rec[:lookup_data][:puc_id] = puc_id
      rec[:missing_mf][:puc_id] = { mode: :direct, raise: true, keys: { farm: seq[:farm] }, msg: "PUC: #{seq[:farm]}" } if puc_id.nil?

      farm_id = po_repo.find_farm_id(puc_id)
      farm_or_puc_desc = if farm_id.nil?
                           "PUC: #{seq[:farm]}"
                         else
                           "farm: #{po_repo.get(:farms, farm_id, :farm_code)}"
                         end
      rec[:lookup_data][:farm_id] = farm_id
      rec[:missing_mf][:farm_id] = { mode: :indirect, raise: true, keys: { puc_id: puc_id }, msg: "Farm for PUC: #{seq[:farm]}" } if farm_id.nil?
      orchard_id = if seq[:orchard].nil_or_empty? && AppConst::CR_EDI.create_unknown_orchard?
                     po_repo.find_unknown_orchard_id(farm_id, puc_id)
                   else
                     po_repo.find_orchard_id(farm_id, seq[:orchard])
                   end
      rec[:lookup_data][:orchard_id] = orchard_id
      rec[:missing_mf][:orchard_id] = { mode: :direct, raise: false, keys: { farm_id: farm_id, orchard: seq[:orchard] }, msg: "Orchard: #{seq[:orchard]} for #{farm_or_puc_desc}" } if orchard_id.nil?

      marketing_variety_id = po_repo.find_marketing_variety_id(seq[:variety])
      rec[:lookup_data][:marketing_variety_id] = marketing_variety_id
      rec[:missing_mf][:marketing_variety_id] = { mode: :direct, raise: true, keys: { variety: seq[:variety] }, msg: "Marketing variety: #{seq[:variety]}" } if marketing_variety_id.nil?
      cultivar_id = po_repo.find_cultivar_id_from_mkv(marketing_variety_id)
      rec[:lookup_data][:cultivar_id] = cultivar_id
      rec[:missing_mf][:cultivar_id] = { mode: :indirect, keys: { marketing_variety_id: marketing_variety_id }, msg: "Cultivar for variety: #{seq[:variety]}" } if cultivar_id.nil?
      cultivar_group_id = po_repo.find_cultivar_group_id(cultivar_id)
      rec[:lookup_data][:cultivar_group_id] = cultivar_group_id
      rec[:missing_mf][:cultivar_group_id] = { mode: :indirect, keys: { cultivar_id: cultivar_id }, msg: "Cultivar Group for variety: #{seq[:variety]}" } if cultivar_group_id.nil?
      season_id = MasterfilesApp::CalendarRepo.new.get_season_id(cultivar_id, inspec_date || tran_date) unless cultivar_id.nil?
      season_cultivar_desc = if cultivar_id.nil?
                               "cultivar of Marketing Variety: #{seq[:variety]}"
                             else
                               "cultivar: #{po_repo.get(:cultivars, cultivar_id, :cultivar_code)}"
                             end
      rec[:lookup_data][:season_id] = season_id
      rec[:missing_mf][:season_id] = { mode: :direct, raise: true, keys: { date: inspec_date || tran_date, cultivar_id: cultivar_id }, msg: "Season for #{season_cultivar_desc} covering date: #{(inspec_date || tran_date).to_date}" } if season_id.nil?
      marketing_org_party_role_id = MasterfilesApp::PartyRepo.new.find_party_role_from_org_code_for_role(seq[:orgzn], AppConst::ROLE_MARKETER)
      marketing_org_party_role_id = po_repo.find_variant_id(:marketing_party_roles, seq[:orgzn]) if marketing_org_party_role_id.nil?
      rec[:lookup_data][:marketing_org_party_role_id] = marketing_org_party_role_id
      rec[:missing_mf][:marketing_org_party_role_id] = { mode: :direct, keys: { orgzn: seq[:orgzn], role: AppConst::ROLE_MARKETER }, msg: "Organization: #{seq[:orgzn]} with role: #{AppConst::ROLE_MARKETER}" } if marketing_org_party_role_id.nil?

      # --------------------- TARGET MARKET RELATED
      targets = po_repo.find_targets(seq[:targ_mkt], seq[:target_region], seq[:target_country])
      rec[:lookup_data][:packed_tm_group_id] = targets.instance[:packed_tm_group_id]
      rec[:missing_mf][:packed_tm_group_id] = { mode: :direct, raise: false, keys: { targ_mkt: seq[:targ_mkt] }, msg: "Target Market Group: #{seq[:targ_mkt]}" } if targets.instance[:packed_tm_group_id].nil?
      rec[:lookup_data][:target_market_id] = targets.instance[:target_market_id] unless targets.instance[:single]

      # The EDI targ_mkt has not been applied as a packed tm grp or target market, so we expect it to be a target customer:
      if targets.instance[:check_customer]
        target_customer_party_role_id = MasterfilesApp::PartyRepo.new.find_party_role_from_org_code_for_role(seq[:targ_mkt], AppConst::ROLE_TARGET_CUSTOMER)
        target_customer_party_role_id = po_repo.find_variant_id(:target_customer_party_roles, seq[:targ_mkt]) if target_customer_party_role_id.nil?
        rec[:lookup_data][:target_customer_party_role_id] = target_customer_party_role_id
        rec[:missing_mf][:target_customer_party_role_id] = { mode: :direct, keys: { targ_mkt: seq[:targ_mkt], role: AppConst::ROLE_TARGET_CUSTOMER }, msg: "Organization: #{seq[:targ_mkt]} with role: #{AppConst::ROLE_TARGET_CUSTOMER}" } if target_customer_party_role_id.nil?
      end
      # ---------------------

      mark_id = po_repo.find_mark_id(seq[:mark])
      rec[:lookup_data][:mark_id] = mark_id
      rec[:missing_mf][:mark_id] = { mode: :direct, raise: false, keys: { mark: seq[:mark] }, msg: "Mark: #{seq[:mark]}" } if mark_id.nil?
      inventory_code_id = po_repo.find_inventory_code_id(seq[:inv_code] || AppConst::CR_EDI.default_edi_in_inv_code)
      rec[:lookup_data][:inventory_code_id] = inventory_code_id
      rec[:missing_mf][:inventory_code_id] = { mode: :direct, raise: false, keys: { inv_code: seq[:inv_code] }, msg: "Inventory code: #{seq[:inv_code]}" } if inventory_code_id.nil?
      grade_id = po_repo.find_grade_id(seq[:grade])
      rec[:lookup_data][:grade_id] = grade_id
      rec[:missing_mf][:grade_id] = { mode: :direct, keys: { grade: seq[:grade] }, msg: "Grade: #{seq[:grade]}" } if grade_id.nil?

      rec[:lookup_data][:basic_pack_code_id] = parent[:lookup_data][:basic_pack_code_id]
      rec[:lookup_data][:standard_pack_code_id] = parent[:lookup_data][:standard_pack_code_id]
      rec[:lookup_data][:pallet_format_id] = parent[:lookup_data][:pallet_format_id]
      rec[:lookup_data][:cartons_per_pallet_id] = parent[:lookup_data][:cartons_per_pallet_id]

      rec[:record] = {
        depot_pallet: true,
        pallet_number: pallet_number,
        carton_quantity: seq[:ctn_qty].to_i,
        pick_ref: seq[:pick_ref],
        sell_by_code: seq[:sellbycode],
        product_chars: seq[:prod_char]   # ???
      }
      records[pallet_number][:sub_records] << rec
    end
  end
end
