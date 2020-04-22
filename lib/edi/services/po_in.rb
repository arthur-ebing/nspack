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

    def create_missing_masterfiles # rubocop:disable Metrics/AbcSize
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

    def check_missing_mf # rubocop:disable Metrics/AbcSize
      auto_create = AppConst::EDI_AUTO_CREATE_MF
      errs = []
      records.each do |_, pallet|
        pallet[:missing_mf].each do |code, rule|
          errs << "Missing masterfile - #{code}, #{rule[:keys].inspect}" if rule[:raise] || !auto_create
        end

        pallet[:sub_records].each do |rec|
          rec[:missing_mf].each do |code, rule|
            errs << "Missing masterfile - #{code}, #{rule[:keys].inspect}" if rule[:raise] || !auto_create
          end
        end
      end

      if errs.empty?
        ok_response
      else
        note = <<~STR
          Please add the missing masterfiles or create variants for them if applicable.

          Then go to #{AppConst::URL_BASE.chomp('/')}/edi/viewer/received/errors
          Select the line for file #{file_name} and click on "re-process this file" to retry this process.
        STR
        failed_response('Missing masterfiles', "\n#{errs.uniq.join("\n").gsub('{', '(').gsub('}', ')')}\n\n#{note}")
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
      location_id = MasterfilesApp::LocationRepo.new.location_id_from_short_code(AppConst::INSTALL_LOCATION)
      raise Crossbeams::InfoError, "There is no INSTALL location named #{AppConst::INSTALL_LOCATION}" if location_id.nil?

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

      standard_pack_code_id = po_repo.find_standard_pack_code_id(seq[:pack])
      rec[:lookup_data][:standard_pack_code_id] = standard_pack_code_id
      rec[:missing_mf][:standard_pack_code_id] = { mode: :direct, raise: false, keys: { pack: seq[:pack] } } if standard_pack_code_id.nil?

      fruit_size_reference_id = po_repo.find_fruit_size_reference_id(seq[:size_count])
      rec[:lookup_data][:fruit_size_reference_id] = fruit_size_reference_id
      rec[:missing_mf][:fruit_size_reference_id] = { mode: :direct, raise: false, keys: { size_count: seq[:size_count] } } if fruit_size_reference_id.nil?

      basic_pack_code_id = po_repo.find_basic_pack_code_id(standard_pack_code_id)
      rec[:lookup_data][:basic_pack_code_id] = basic_pack_code_id
      rec[:missing_mf][:basic_pack_code_id] = { mode: :direct, raise: false, keys: { size_count: seq[:size_count] } } if basic_pack_code_id.nil?

      pallet_format_id, cartons_per_pallet_id = po_repo.find_pallet_format_and_cpp_id(seq[:pallet_btype], tot_cartons, basic_pack_code_id)
      rec[:lookup_data][:pallet_format_id] = pallet_format_id
      rec[:missing_mf][:pallet_format_id] = { mode: :direct, raise: true, keys: { pallet_btype: seq[:pallet_btype], cartons: tot_cartons, basic_pack_code_id: basic_pack_code_id } } if pallet_format_id.nil?
      rec[:lookup_data][:cartons_per_pallet_id] = cartons_per_pallet_id
      rec[:missing_mf][:cartons_per_pallet_id] = { mode: :direct, raise: true, keys: { pallet_btype: seq[:pallet_btype], cartons: tot_cartons, basic_pack_code_id: basic_pack_code_id } } if cartons_per_pallet_id.nil?

      # pallet_format_id: 0, # lookup
      rec[:record] = {
        depot_pallet: true,
        edi_in_consignment_note_number: seq[:cons_no],
        edi_in_transaction_id: edi_in_transaction.id,
        pallet_number: pallet_number,
        location_id: location_id,
        in_stock: true,
        inspected: !orig_inspec_date.nil? || !inspec_date.nil?,
        govt_first_inspection_at: orig_inspec_date || inspec_date,
        govt_reinspection_at: reinspect_at,
        stock_created_at: intake_date || inspec_date || Time.now,
        phc: seq[:packh_code],
        intake_created_at: intake_date,
        gross_weight: seq[:pallet_gross_mass].nil? || seq[:pallet_gross_mass].to_f.zero? ? nil : seq[:pallet_gross_mass],
        gross_weight_measured_at: weighed_date,
        palletized: true,
        palletized_at: intake_date,
        created_at: intake_date,
        reinspected: !reinspect_at.nil?,
        govt_inspection_passed: !orig_inspec_date.nil? || !inspec_date.nil?,
        cooled: false,
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
      rec[:missing_mf][:puc_id] = { mode: :direct, raise: true, keys: { farm: seq[:farm] } } if puc_id.nil?

      farm_id = po_repo.find_farm_id(puc_id)
      rec[:lookup_data][:farm_id] = farm_id
      rec[:missing_mf][:farm_id] = { mode: :indirect, raise: true, keys: { puc_id: puc_id } } if farm_id.nil?
      orchard_id = po_repo.find_orchard_id(farm_id, seq[:orchard])
      rec[:lookup_data][:orchard_id] = orchard_id
      rec[:missing_mf][:orchard_id] = { mode: :direct, raise: false, keys: { farm_id: farm_id, orchard: seq[:orchard] } } if orchard_id.nil?
      marketing_variety_id = po_repo.find_marketing_variety_id(seq[:variety])
      rec[:lookup_data][:marketing_variety_id] = marketing_variety_id
      rec[:missing_mf][:marketing_variety_id] = { mode: :direct, raise: true, keys: { variety: seq[:variety] } } if marketing_variety_id.nil?
      cultivar_id = po_repo.find_cultivar_id_from_mkv(marketing_variety_id)
      rec[:lookup_data][:cultivar_id] = cultivar_id
      rec[:missing_mf][:cultivar_id] = { mode: :indirect, keys: { marketing_variety_id: marketing_variety_id } } if cultivar_id.nil?
      cultivar_group_id = po_repo.find_cultivar_group_id(cultivar_id)
      rec[:lookup_data][:cultivar_group_id] = cultivar_group_id
      rec[:missing_mf][:cultivar_group_id] = { mode: :indirect, keys: { cultivar_id: cultivar_id } } if cultivar_group_id.nil?
      season_id = po_repo.find_season_id(inspec_date || tran_date, cultivar_id)
      rec[:lookup_data][:season_id] = season_id
      rec[:missing_mf][:season_id] = { mode: :direct, raise: true, keys: { date: inspec_date || tran_date, cultivar_id: cultivar_id } } if season_id.nil?
      marketing_org_party_role_id = MasterfilesApp::PartyRepo.new.find_party_role_from_org_code_for_role(seq[:orgzn], AppConst::ROLE_MARKETER)
      marketing_org_party_role_id = po_repo.find_variant_id(:marketing_party_roles, seq[:orgzn]) if marketing_org_party_role_id.nil?
      rec[:lookup_data][:marketing_org_party_role_id] = marketing_org_party_role_id
      rec[:missing_mf][:marketing_org_party_role_id] = { mode: :direct, keys: { orgzn: seq[:orgzn], role: AppConst::ROLE_MARKETER } } if marketing_org_party_role_id.nil?
      packed_tm_group_id = po_repo.find_packed_tm_group_id(seq[:targ_mkt])
      rec[:lookup_data][:packed_tm_group_id] = packed_tm_group_id
      rec[:missing_mf][:packed_tm_group_id] = { mode: :direct, raise: false, keys: { targ_mkt: seq[:targ_mkt] } } if packed_tm_group_id.nil?
      mark_id = po_repo.find_mark_id(seq[:mark])
      rec[:lookup_data][:mark_id] = mark_id
      rec[:missing_mf][:mark_id] = { mode: :direct, raise: false, keys: { mark: seq[:mark] } } if mark_id.nil?
      inventory_code_id = po_repo.find_inventory_code_id(seq[:inv_code])
      rec[:lookup_data][:inventory_code_id] = inventory_code_id
      rec[:missing_mf][:inventory_code_id] = { mode: :direct, raise: false, keys: { inv_code: seq[:inv_code] } } if inventory_code_id.nil?
      grade_id = po_repo.find_grade_id(seq[:grade])
      rec[:lookup_data][:grade_id] = grade_id
      rec[:missing_mf][:grade_id] = { mode: :direct, keys: { grade: seq[:grade] } } if grade_id.nil?

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
