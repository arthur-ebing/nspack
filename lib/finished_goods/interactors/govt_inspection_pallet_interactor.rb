# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPalletInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_govt_inspection_pallet(params)
      res = validate_govt_inspection_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_govt_inspection_pallet(res)
      end
      instance = govt_inspection_pallet(id)
      success_response('Created govt inspection pallet', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { failure_remarks: ['This govt inspection pallet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def fail_govt_inspection_pallet(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_govt_inspection_failed_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      govt_inspection_sheet_id = repo.get(:govt_inspection_pallets, id, :govt_inspection_sheet_id)
      reinspection = repo.get(:govt_inspection_sheets, govt_inspection_sheet_id, :reinspection)
      attrs = res.to_h
      attrs[:passed] = false
      attrs[:inspected] = true
      if reinspection
        attrs[:reinspected] = true
        attrs[:reinspected_at] = Time.now
      else
        attrs[:inspected_at] = Time.now
      end
      repo.transaction do
        repo.update_govt_inspection_pallet(id, attrs)
      end
      instance = govt_inspection_pallet(id)
      success_response('Govt inspection: pallet failed.', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def pass_govt_inspection_pallet(ids) # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet_ids = repo.select_values(:govt_inspection_pallets, :govt_inspection_sheet_id, id: ids).uniq
      govt_inspection_sheet_ids.each do |sheet_id|
        reinspection = repo.get(:govt_inspection_sheets, sheet_id, :reinspection)
        attrs = { passed: true, inspected: true, failure_reason_id: nil, failure_remarks: nil }
        if reinspection
          attrs[:reinspected] = true
          attrs[:reinspected_at] = Time.now
        else
          attrs[:inspected_at] = Time.now
        end
        repo.transaction do
          [ids].each do |id|
            repo.update_govt_inspection_pallet(id, attrs)
          end
        end
      end
      success_response('Govt inspection: pallets passed.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_pallet(id, params)
      res = validate_govt_inspection_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_govt_inspection_pallet(id, attrs)
      end
      instance = govt_inspection_pallet(id)
      success_response('Updated govt inspection pallet', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_pallet(id)
      instance = govt_inspection_pallet(id)
      repo.transaction do
        repo.delete_govt_inspection_pallet(id)
      end
      success_response('Deleted govt inspection pallet', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionPallet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def reject_to_repack(multiselect_list)  # rubocop:disable Metrics/AbcSize
      return failed_response('Pallet selection cannot be empty') if multiselect_list.nil_or_empty?

      pallet_ids = repo.select_values(:pallet_sequences, :pallet_id, id: multiselect_list).uniq
      new_pallet_ids = []
      repo.transaction do
        pallet_ids.each do |pallet_id|
          next if pallet_id.nil_or_empty?

          res = FinishedGoodsApp::RepackPallet.call(pallet_id, @user.user_name, true)
          return res unless res.success

          new_pallet_ids << res.instance[:new_pallet_id]
        end
        pallet_numbers = reworks_repo.find_pallet_numbers(pallet_ids)
        res = create_reworks_run(pallet_numbers)
        return res unless res.success

        repo.log_multiple_statuses(:pallets, pallet_ids, AppConst::REWORKS_REPACK_PALLET_STATUS)
        repo.log_multiple_statuses(:pallet_sequences, reworks_repo.pallet_sequence_ids(pallet_ids), AppConst::REWORKS_REPACK_PALLET_STATUS)
        repo.log_multiple_statuses(:pallets, new_pallet_ids, AppConst::REWORKS_REPACK_PALLET_NEW_STATUS)
        repo.log_multiple_statuses(:pallet_sequences, reworks_repo.pallet_sequence_ids(new_pallet_ids), AppConst::REWORKS_REPACK_PALLET_STATUS)
      end

      success_response('Selected pallets have been repacked successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('reject_to_repack'))
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def create_reworks_run(pallet_numbers)  # rubocop:disable Metrics/AbcSize
      reworks_run_type_id = reworks_repo.get_reworks_run_type_id(AppConst::RUN_TYPE_SCRAP_PALLET)
      return failed_response("Reworks Run Type : #{AppConst::RUN_TYPE_SCRAP_PALLET} does not exist. Perhaps required seeds were not run. Please contact support.") if reworks_run_type_id.nil?

      scrap_reason_id = reworks_repo.get_scrap_reason_id(AppConst::REWORKS_REPACK_SCRAP_REASON)
      return failed_response("Scrap Reason : #{AppConst::REWORKS_REPACK_SCRAP_REASON} does not exist. Perhaps required seeds were not run. Please contact support.") if scrap_reason_id.nil?

      reworks_repo.create_reworks_run(user: @user.user_name,
                                      reworks_run_type_id: reworks_run_type_id,
                                      scrap_reason_id: scrap_reason_id,
                                      remarks: AppConst::REWORKS_REPACK_SCRAP_REASON,
                                      pallets_scrapped: "{ #{pallet_numbers.join(',')} }",
                                      pallets_affected: "{ #{pallet_numbers.join(',')} }")

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= GovtInspectionRepo.new
    end

    def reworks_repo
      @reworks_repo ||= ProductionApp::ReworksRepo.new
    end

    def govt_inspection_pallet(id)
      repo.find_govt_inspection_pallet_flat(id)
    end

    def validate_govt_inspection_pallet_params(params)
      GovtInspectionPalletSchema.call(params)
    end

    def validate_govt_inspection_failed_pallet_params(params)
      GovtInspectionFailedPalletSchema.call(params)
    end
  end
end
