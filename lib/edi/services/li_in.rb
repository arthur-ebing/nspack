# frozen_string_literal: true

module EdiApp
  class LiIn < BaseEdiInService # rubocop:disable Metrics/ClassLength
    attr_accessor :attrs, :missing_masterfiles, :order_items
    attr_reader :repo, :li_repo, :po_repo, :order_head, :order_item_recs, :file_name, :remarks

    def initialize(edi_in_transaction_id, file_path, logger, edi_result)
      super(edi_in_transaction_id, file_path, logger, edi_result)
      @repo = EdiApp::EdiInRepo.new
      @li_repo = LiInRepo.new
      @po_repo = PoInRepo.new
      @attrs = {}
      @order_head = nil
      @order_item_recs = []
      @missing_masterfiles = []
      @order_items = []
      @remarks = []
      @file_name = @repo.get(:edi_in_transactions, edi_in_transaction_id, :file_name)
    end

    # Go through the LD records.
    # The first few records arrive with location code set to Xs - this represents the "header".
    # Use the trailing text of these rows to build up a remarks variable.
    # All other LD records represent a combination of the order and an order item.
    def call # rubocop:disable Metrics/AbcSize
      log "Got: #{edi_records.length} recs"

      prepare_records

      res = do_not_proceed?
      return res if res.sucess

      # If revision is "9", delete the order by matching on customer_order_number.
      # Else (revision is "0", create a new order or ignore if the order already exists.
      existing_id = check_for_existing_order
      return process_delete(existing_id) if delete_li?
      return success_response('LI ignored - order exists already') unless existing_id.nil?

      # Build order and order items attributes in memory.
      parse_order_edi
      parse_order_items_edi

      mf_res = check_missing_masterfiles
      return mf_res unless mf_res.success

      business_validation_passed

      create_order
      success_response('LI processed')
    end

    private

    def do_not_proceed?
      # Check if an LI should be processed for the org in this file:
      return success_response("LI ignored for org: #{order_head[:organization]}") unless AppConst::CR_EDI.process_li_for_org?(order_head[:organization])

      failed_response('Continue to process')
    end

    def prepare_records
      edi_records.each do |rec|
        rec_type = resolve_type(rec)
        next if %w[BH BT].include?(rec_type)
        raise Crossbeams::FrameworkError, "LI: not set up to handle #{rec_type} record type" unless rec_type == 'LD'

        if rec[:location_code] == 'XXXXXXX'
          remarks << rec[:everything_else]
          next
        end
        @order_head ||= rec
        @order_item_recs << rec
      end
    end

    def resolve_type(rec)
      (rec[:record_type] || rec[:header] || rec[:trailer]).to_s
    end

    def delete_li?
      order_head[:revision] == '9'
    end

    def check_for_existing_order
      li_repo.get_id(:orders, customer_order_number: order_head[:order_number])
    end

    def process_delete(existing_id)
      return success_response('LI delete ignored - no matching order') if existing_id.nil?

      li_repo.transaction do
        li_repo.delete_order(existing_id, file_name)
      end
      success_response("LI delete processed. Order with id #{existing_id} deleted.")
    end

    def parse_order_edi # rubocop:disable Metrics/AbcSize
      attrs[:customer_party_role_id] = get_party_role_id(order_head[:organization], AppConst::ROLE_CUSTOMER)
      attrs[:exporter_party_role_id] = get_party_role_id(order_head[:sender], AppConst::ROLE_EXPORTER)
      attrs[:marketing_org_party_role_id] = get_party_role_id(order_head[:sender], AppConst::ROLE_MARKETER)

      # T-Cust / TM / packed
      attrs[:packed_tm_group_id] = po_repo.find_packed_tm_group_id(order_head[:target_market])
      missing_masterfiles << "Packed TM Group: #{order_head[:target_market]}" if attrs[:packed_tm_group_id].nil?

      # # --------------------- TARGET MARKET RELATED
      # targets = po_repo.find_targets(seq[:targ_mkt], seq[:target_region], seq[:target_country]) # (target_market) (?) (LD.country)
      # rec[:lookup_data][:packed_tm_group_id] = targets.instance[:packed_tm_group_id]
      # rec[:missing_mf][:packed_tm_group_id] = { mode: :direct, raise: false, keys: { targ_mkt: seq[:targ_mkt] }, msg: "Target Market Group: #{seq[:targ_mkt]}" } if targets.instance[:packed_tm_group_id].nil?
      # rec[:lookup_data][:target_market_id] = targets.instance[:target_market_id] unless targets.instance[:single]
      #
      # # The EDI targ_mkt has not been applied as a packed tm grp or target market, so we expect it to be a target customer:
      # if targets.instance[:check_customer]
      #   target_customer_party_role_id = MasterfilesApp::PartyRepo.new.find_party_role_from_org_code_for_role(seq[:targ_mkt], AppConst::ROLE_TARGET_CUSTOMER)
      #   target_customer_party_role_id = po_repo.find_variant_id(:target_customer_party_roles, seq[:targ_mkt]) if target_customer_party_role_id.nil?
      #   rec[:lookup_data][:target_customer_party_role_id] = target_customer_party_role_id
      #   rec[:missing_mf][:target_customer_party_role_id] = { mode: :direct, keys: { targ_mkt: seq[:targ_mkt], role: AppConst::ROLE_TARGET_CUSTOMER }, msg: "Organization: #{seq[:targ_mkt]} with role: #{AppConst::ROLE_TARGET_CUSTOMER}" } if target_customer_party_role_id.nil?
      # end
      # # ---------------------

      attrs[:customer_order_number] = order_head[:order_number]
      attrs[:remarks] = remarks.join("\n")

      res = li_repo.latest_values_from_order(attrs[:customer_party_role_id])
      if res.success
        attrs[:incoterm_id] = res.instance[:incoterm_id]
        attrs[:deal_type_id] = res.instance[:deal_type_id]
        attrs[:currency_id] = res.instance[:currency_id]
        attrs[:order_type_id] = res.instance[:order_type_id]
        attrs[:customer_payment_term_set_id] = res.instance[:customer_payment_term_set_id]
      else
        missing_masterfiles << 'No Previous Order found to use for setting incoterms etc.'
      end
    end

    def parse_order_items_edi # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      order_item_recs.each do |rec| # rubocop:disable Metrics/BlockLength
        item = { carton_quantity: rec[:instruction_quantity].to_i }

        standard_pack_code_id = po_repo.find_standard_pack_id(rec[:pack])
        item[:standard_pack_id] = standard_pack_code_id
        missing_masterfiles << "Standard Pack: #{rec[:pack]}" if standard_pack_code_id.nil?

        pallet_base_type = rec[:pallet_base_type] || AppConst::CR_EDI.li_default_pallet_base
        pallet_format_id = li_repo.find_pallet_format_id(pallet_base_type, AppConst::CR_EDI.li_default_pallet_stack_height)
        item[:pallet_format_id] = pallet_format_id
        missing_masterfiles << "Pallet Format - Base: #{pallet_base_type}, Stack height: #{AppConst::CR_EDI.li_default_pallet_stack_height}" if pallet_format_id.nil?

        _, basic_pack_code_id = li_repo.find_cartons_per_pallet_and_basic_pack_code(pallet_format_id, standard_pack_code_id)
        item[:basic_pack_id] = basic_pack_code_id
        missing_masterfiles << "Basic Pack: #{rec[:pack]}" if basic_pack_code_id.nil?

        mark_id = po_repo.find_mark_id(rec[:mark])
        item[:mark_id] = mark_id
        missing_masterfiles << "Mark: #{rec[:mark]}" if mark_id.nil?

        inventory_code_id = po_repo.find_inventory_code_id(rec[:inventory_code])
        item[:inventory_id] = inventory_code_id
        missing_masterfiles << "Inventory Code: #{rec[:inventory_code]}" if inventory_code_id.nil?

        grade_id = po_repo.find_grade_id(rec[:grade])
        item[:grade_id] = grade_id
        missing_masterfiles << "Grade: #{rec[:grade]}" if grade_id.nil?

        marketing_variety_id = po_repo.find_marketing_variety_id(rec[:variety])
        item[:marketing_variety_id] = marketing_variety_id
        missing_masterfiles << "Marketing Variety: #{rec[:variety]}" if marketing_variety_id.nil?

        commodity_id = li_repo.find_commodity_id(rec[:commodity])
        item[:commodity_id] = commodity_id
        missing_masterfiles << "Commodity: #{rec[:commodity]}" if commodity_id.nil?

        fruit_size_reference_id = po_repo.find_fruit_size_reference_id(rec[:low_count])
        item[:size_reference_id] = fruit_size_reference_id
        missing_masterfiles << "Size Reference: #{rec[:low_count]}" if fruit_size_reference_id.nil?

        actual_count_id = li_repo.find_actual_count_id(commodity_id, basic_pack_code_id, rec[:low_count])
        item[:actual_count_id] = actual_count_id
        missing_masterfiles << "Actual Count - Commodity: #{rec[:commodity]} Pack: #{rec[:pack]} Count: #{rec[:low_count]}" if actual_count_id.nil?

        order_items << item
      end
    end

    def create_order # rubocop:disable Metrics/AbcSize
      li_repo.transaction do
        order_id = li_repo.create(:orders, attrs)

        item_ids = []
        order_items.each do |item|
          item_ids << li_repo.create(:order_items, item.merge(order_id: order_id))
        end

        li_repo.log_status(:orders, order_id, 'CREATED FROM LI', comment: file_name, user_name: 'System')
        li_repo.log_multiple_statuses(:order_items, item_ids, 'CREATED FROM LI', comment: file_name, user_name: 'System')
        li_repo.log_action(user_name: 'System', context: 'EDI', route_url: 'LI EDI IN')
      end
    end

    def get_party_role_id(party_role_name, role_name)
      return nil if party_role_name.nil_or_empty?

      role_id = repo.get_id(:roles, name: role_name)
      raise Crossbeams::InfoError, "There is no role #{role_name}" if role_id.nil?

      org_id = repo.get_case_insensitive_match(:organizations, short_description: party_role_name)
      org_id ||= repo.get_variant_id(:organizations, party_role_name)
      id = repo.get_id(:party_roles, role_id: role_id, organization_id: org_id)
      return id unless id.nil?

      missing_masterfiles << "Organization: #{role_name.capitalize} - #{party_role_name}"
      id
    end

    def get_case_insensitive_match_or_variant(table_name, args)
      id = repo.get_case_insensitive_match(table_name, args)
      return id unless id.nil?

      col, val = args.first
      id = repo.get_variant_id(table_name, val)
      return id unless id.nil?

      missing_masterfiles << "#{table_name.capitalize}: #{col.capitalize} - #{val}"
      id
    end

    def check_missing_masterfiles
      return ok_response if missing_masterfiles.empty?

      notes = missing_masterfiles.join(", \n")
      missing_masterfiles_detected(notes)

      note = <<~STR
        Please add the missing masterfiles or create variants for them if applicable.

        Then go to #{AppConst::URL_BASE.chomp('/')}/edi/viewer/received/errors
        Select the line for file #{file_name} and click on "re-process this file" to retry this process.
      STR
      failed_response('Missing masterfiles', "\n#{notes}\n\n#{note}")
    end
  end
end
