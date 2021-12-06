# frozen_string_literal: true

module EdiApp
  class ActionsInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def send_ps(params)
      res = check_for_recent_job(params[:party_role_id])
      return res unless res.success

      EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_PS, params[:party_role_id], @user.user_name)
    end

    def check_for_recent_job(id)
      return failed_response('There is already a job enqueued to send PS') if EdiApp::Job::SendEdiOut.enqueued_with_args?(AppConst::EDI_FLOW_PS, id)

      # Check for anything enqueued within 5 mins...
      ok_response
    end

    def re_receive_file(file)
      logger = Logger.new(File.join(ENV['ROOT'], 'log', 'edi_in.log'), 'weekly')
      new_path = File.join(AppConst::EDI_RECEIVE_DIR, File.basename(file))

      logger.info("Re-receive: Moving: #{file} to #{new_path}")
      FileUtils.mv(file, new_path)

      logger.info("Re-receive: Enqueuing #{new_path} for EdiApp::Job::ReceiveEdiIn")
      Que.enqueue new_path, job_class: 'EdiApp::Job::ReceiveEdiIn', queue: AppConst::QUEUE_NAME

      success_response('The file has been enqued to be re-processed.')
    end

    def re_receive_file_from_transaction(id)
      full_path = in_repo.file_path_for_edi_in_transaction(id)
      re_receive_file(full_path)
    end

    def create_manual_intake
      in_repo.create(:edi_in_transactions,
                     file_name: "manual-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}",
                     flow_type: 'PO',
                     manual_process: true)
    end

    def update_edi_manual_intake_header(id, params)
      res = validate_edi_manual_intake_header(params)
      return validation_failed_response(res) if res.failure?

      in_repo.transaction do
        in_repo.update_edi_in_transaction(id, manual_header: res.to_h)
        log_transaction
      end
      instance = edi_in_transaction(id)
      success_response('Updated manual intake header', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def process_manual_transaction(id) # rubocop:disable Metrics/AbcSize
      flow_type = 'PO'

      logger = Logger.new(File.join(ENV['ROOT'], 'log', 'edi_in.log'), 'weekly')
      edi_result = OpenStruct.new(schema_valid: false,
                                  newer_edi_received: false,
                                  has_missing_master_files: false,
                                  valid: true,
                                  has_discrepancies: false,
                                  recordset: nil,
                                  notes: nil)
      res = nil
      in_repo.transaction do
        res = EdiApp::PoIn.call(id, 'manual', logger, edi_result)
        if res.success
          logger.info "Manual process for id #{id}: Completed: #{res.message}"
          in_repo.log_edi_in_complete(id, res.message, edi_result)
        else
          email_notifiers = DevelopmentApp::UserRepo.new.email_addresses(user_email_group: AppConst::EMAIL_GROUP_EDI_NOTIFIERS)
          logger.info "Manual process for id #{id}: Failed: #{res.message}"
          in_repo.log_edi_in_failed(id, res.message, res.instance, edi_result)
          msg = res.instance.empty? ? res.message : "\n#{res.message}\n#{res.instance}"
          ErrorMailer.send_error_email(subject: "EDI in #{flow_type} transform failed (transaction id: #{id})",
                                       message: msg,
                                       append_recipients: email_notifiers)
        end
      end
      res
    end

    def manual_intake_items_grid(id)
      instance = edi_in_transaction(id)
      row_defs = (instance.recordset || []).map { |rec| UtilityFunctions.symbolize_keys(rec) }.select  { |rec| rec[:record_type].to_s == 'OP' }
      row_defs.each_with_index { |row, index| row[:id] = index }
      {
        fieldUpdateUrl: "/edi/actions/edit_manual_intake/#{id}/inline_edit/$:id$",
        columnDefs: col_defs_for_manual_intake,
        rowDefs: row_defs
      }.to_json
    end

    def col_defs_for_manual_intake # rubocop:disable Metrics/AbcSize
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk| # rubocop:disable Metrics/BlockLength
        mk.integer 'id', 'id'
        mk.col 'record_type', 'Rec', width: 50, data_type: :string
        # mk.col('sscc', 'Pallet', { width: 200, data_type: :string, editable: true, cellEditor: 'numericCellEditor' })
        mk.col 'sscc', 'Pallet', width: 200, data_type: :string, editable: true
        mk.integer 'seq_no', 'Seq', editable: true
        mk.col 'farm', 'PUC', editable: true
        mk.col 'mark', 'Mark', editable: true
        mk.col 'pack', 'Pack', editable: true
        mk.col 'grade', nil, editable: true
        mk.col 'orgzn', 'Org', editable: true
        mk.col 'cons_no', nil, editable: true
        mk.integer 'ctn_qty', nil, editable: true
        mk.col 'orchard', nil, editable: true
        mk.col 'variety', nil, editable: true
        mk.col 'inv_code', nil, editable: true
        mk.integer 'pick_ref', nil, editable: true
        mk.col 'targ_mkt', nil, editable: true
        mk.col 'orig_cons', nil, editable: true
        mk.col 'prod_char', nil, editable: true
        mk.integer 'tran_date', nil, editable: true
        mk.col 'packh_code', nil, editable: true
        mk.col 'sellbycode', nil, editable: true
        mk.col 'size_count', nil, editable: true
        mk.integer 'inspec_date', nil, editable: true
        mk.col 'inspect_pnt', nil, editable: true
        mk.integer 'intake_date', nil, editable: true
        mk.col 'pallet_btype', nil, editable: true
        mk.col 'target_region', nil, editable: true
        mk.col 'weighing_date', nil, editable: true
        mk.col 'weighing_time', nil, editable: true
        mk.col 'target_country', nil, editable: true
        mk.col 'temp_device_id', nil, editable: true
        mk.integer 'orig_inspec_date', nil, editable: true
        mk.col 'pallet_gross_mass', nil, editable: true
      end
    end

    def update_op_recordset(id, index, params) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      key = params[:column_name]
      new_val = params[:column_value]
      new_val = nil if new_val == 'undefined'
      if !new_val.nil? && %w[tran_date inspec_date intake_date orig_inspec_date].include?(key)
        return failed_response("#{key} must be in format YYYYMMDD") if new_val.length != 8
        return failed_response("#{key} must be in format YYYYMMDD, #{new_val[4, 2]} is an invalid month") unless new_val[4, 2] =~ /(0[1-9]|1[0-2])/
        return failed_response("#{key} must be in format YYYYMMDD, #{new_val[6, 2]} is an invalid day") unless new_val[6, 2] =~ /(0[1-9]|[12][0-9]|3[01])/
      end
      instance = edi_in_transaction(id)
      pos = -1
      do_update = true
      instance.recordset.each do |row|
        next unless row['record_type'] == 'OP'

        pos += 1
        if pos == index
          do_update = false if row[key] == new_val
          row[key] = new_val
        end
      end
      in_repo.update(:edi_in_transactions, id, recordset: instance.recordset) if do_update
      success_response(do_update ? "Updated #{key}" : 'no change')
    end

    def add_manual_intake_row(id) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      instance = edi_in_transaction(id)
      header = instance.manual_header || {}
      row_defs = (instance.recordset || []).select  { |rec| rec['record_type'].to_s == 'OP' }
      new_row = { id: row_defs.length,
                  record_type: 'OP',
                  sscc: nil,
                  seq_no: nil,
                  farm: nil,
                  mark: nil,
                  pack: nil,
                  grade: nil,
                  orgzn: nil,
                  cons_no: nil,
                  ctn_qty: nil,
                  orchard: nil,
                  variety: nil,
                  inv_code: nil,
                  pick_ref: nil,
                  targ_mkt: nil,
                  orig_cons: nil,
                  prod_char: nil,
                  tran_date: nil,
                  packh_code: nil,
                  sellbycode: nil,
                  size_count: nil,
                  inspec_date: nil,
                  inspect_pnt: header['edi_in_inspection_point'],
                  intake_date: nil,
                  pallet_btype: nil,
                  target_region: nil,
                  weighing_date: nil,
                  weighing_time: nil,
                  target_country: nil,
                  temp_device_id: nil,
                  orig_inspec_date: nil,
                  pallet_gross_mass: nil }
      row_defs << new_row
      rows = []
      if instance.recordset.nil?
        rows = [{ header: 'BH' },
                { record_type: 'OH' },
                { record_type: 'OL' },
                { record_type: 'OL' },
                { record_type: 'OC' }]
               .push(new_row)
               .push({ record_type: 'BT' })
      else
        first = true
        instance.recordset.each do |row|
          if row['record_type'] == 'OP'
            rows += row_defs if first
            first = false
          else
            rows << row
          end
        end
      end
      in_repo.update(:edi_in_transactions, id, recordset: rows)
      success_response('Added row', new_row)
    end

    private

    def validate_edi_manual_intake_header(params)
      Dry::Schema.Params do
        required(:depot_id).filled(:integer)
        required(:edi_in_inspection_point).filled(Types::StrippedString)
        required(:edi_in_load_number).filled(Types::StrippedString)
      end.call(params)
    end

    def in_repo
      @in_repo ||= EdiInRepo.new
    end

    def repo
      in_repo
    end

    def edi_in_transaction(id)
      in_repo.find_edi_in_transaction(id)
    end
  end
end
