# frozen_string_literal: true

# Load:::
#    Batch Header                -> BH
#    Truck Header                -> OH
#    Truck location from         -> LF (OL in final record)
#    Truck location to           -> LT (OL in final record)
#      `-- Container             -> OK (optional) :: if there, per container, else all in one...
#      `-- Intake Header         -> OC
#            `-- Pallet sequence -> OP
#    Batch Trailer               -> BT
module EdiApp
  class PoOut < BaseEdiOutService # rubocop:disable Metrics/ClassLength
    attr_reader :org_code, :po_repo

    def initialize(edi_out_transaction_id, logger)
      @po_repo = PoOutRepo.new
      super(AppConst::EDI_FLOW_PO, edi_out_transaction_id, logger)
    end

    def call # rubocop:disable Metrics/AbcSize
      log('Starting transform...')
      @oh_count, @ol_count, @oc_count, @ok_count, @op_count = [0, 0, 0, 0, 0] # rubocop:disable Style/ParallelAssignment
      @total_carton_count = 0
      @pallet_nos = Set.new
      prepare_bh
      return success_response('No data for PO') if @header_rec.nil?

      @mail_tokens[:load_id] = record_id
      @mail_tokens[:customer_order_no] = @header_rec[:master_ord]

      prepare_oh
      prepare_lf
      prepare_lt

      recs = po_repo.po_details(record_id).group_by { |r| r[:container] }
      @mail_tokens[:container_code] = recs.keys.join(', ')
      recs.each do |container, details|
        @current_row = details.first
        prepare_ok if container
        prepare_oc
        details.each do |row|
          raise "PO cannot be sent: pallet #{row[:sscc]} has zero carton quantity." if row[:ctn_qty].zero?

          prepare_op(row)
        end
      end

      prepare_bt
      validate_data({ 'OC' => %i[load_id], 'OK' => %i[load_id container], 'OP' => %i[load_id sscc seq_no] }, check_lengths: true)
      fname = create_flat_file

      po_repo.store_edi_filename(fname, record_id, target_depot?)
      log('Ending transform...')
      success_response('PoOut was successful', fname)
    end

    def on_fail(message)
      po_repo.log_po_fail(record_id, message)
    end

    private

    # Is this EDI for the load's depot?
    def target_depot?
      po_repo.target_depot?(edi_out_rule_id, record_id)
    end

    def prepare_bh
      @header_rec = po_repo.po_header_row(record_id)
      return if @header_rec.nil?

      hash = build_hash_from_data(@header_rec, 'BH')
      add_record('BH', hash)
    end

    def prepare_oh
      hash = build_hash_from_data(@header_rec, 'OH')
      hash[:location_code] = AppConst::CR_EDI.install_depot
      add_record('OH', hash)
      @oh_count += 1
    end

    def prepare_lf
      hash = build_hash_from_data(@header_rec, 'LF')
      hash[:locn_code] = AppConst::CR_EDI.install_depot
      add_record('LF', hash)
      @ol_count += 1
    end

    def prepare_lt
      hash = build_hash_from_data(@header_rec, 'LT')
      if AppConst::CR_EDI.install_depot && @header_rec[:next_code] == AppConst::CR_EDI.install_depot
        hash[:locn_type] = 'CU'
        hash[:locn_code] = @header_rec[:customer]
      end
      add_record('LT', hash)
      @ol_count += 1
    end

    def prepare_ok
      hash = build_hash_from_data(@current_row, 'OK')
      hash[:ctn_qty] = @current_row[:tot_ctn_qty]
      hash[:plt_qty] = @current_row[:tot_plt_qty]
      hash[:ship_line] = (@current_row[:ship_line] || '')[0, 1] # Just the 1st char
      hash[:sender] = AppConst::CR_EDI.install_depot
      add_record('OK', hash)
      @ok_count += 1
    end

    def prepare_oc
      hash = build_hash_from_data(@current_row, 'OC')
      hash[:ctn_qty] = @current_row[:tot_ctn_qty]
      hash[:plt_qty] = @current_row[:tot_plt_qty]
      hash[:locn_code] = AppConst::CR_EDI.install_depot
      hash[:cons_type] = if AppConst::CR_EDI.install_depot && @header_rec[:next_code] == AppConst::CR_EDI.install_depot
                           'RL' # 'DP' was the default, but Kromco/TruCape says RL. Remove this comment after 2022 if no other clients have a problem
                         else
                           'OT'
                         end
      add_record('OC', hash)
      @oc_count += 1
    end

    def prepare_op(row)
      hash = build_hash_from_data(row, 'OP')
      hash[:locn_code] = AppConst::CR_EDI.install_depot
      hash[:sender] = AppConst::CR_EDI.install_depot
      hash[:orig_depot] = AppConst::CR_EDI.install_depot

      add_record('OP', hash)
      @total_carton_count += row[:ctn_qty]
      @pallet_nos << row[:sscc]
      @op_count += 1
    end

    def prepare_bt
      add_record('BT',
                 record_count: @oh_count + @ol_count + @oc_count + @ok_count + @op_count + 2,
                 oh_count: @oh_count,
                 ol_count: @ol_count,
                 oc_count: @oc_count,
                 ok_count: @ok_count,
                 op_count: @op_count,
                 total_carton_count: @total_carton_count,
                 total_pallet_count: @pallet_nos.length)
    end
  end
end
