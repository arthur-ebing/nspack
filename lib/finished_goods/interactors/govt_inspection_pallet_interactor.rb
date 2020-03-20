# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPalletInteractor < BaseInteractor # rubocop:disable ClassLength
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

      attrs = res.to_h
      attrs[:inspected] = true
      attrs[:passed] = false
      attrs[:inspected_at] = Time.now

      repo.transaction do
        repo.update_govt_inspection_pallet(id, attrs)
      end
      instance = govt_inspection_pallet(id)
      success_response('Govt inspection: pallet failed.', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def pass_govt_inspection_pallet(ids)
      attrs = { inspected: true,
                inspected_at: Time.now,
                passed: true,
                failure_reason_id: nil,
                failure_remarks: nil }
      repo.transaction do
        [ids].each do |id|
          repo.update_govt_inspection_pallet(id, attrs)
        end
      end
      success_response('Govt inspection: pallets passed.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_pallet(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_govt_inspection_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      govt_inspection_sheet_id = repo.get_id(:govt_inspection_pallets, govt_inspection_sheet_id: id)
      reinspection = repo.get_with_args(:govt_inspection_sheets, :reinspection, id: govt_inspection_sheet_id)

      attrs = res.to_h
      if reinspection
        attrs[:reinspected] = true
        attrs[:reinspected_at] = Time.now
      end

      repo.transaction do
        repo.update_govt_inspection_pallet(id, attrs)
      end
      instance = govt_inspection_pallet(id)
      success_response('Updated govt inspection pallet', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_pallet(id)
      repo.transaction do
        repo.delete_govt_inspection_pallet(id)
      end
      success_response('Deleted govt inspection pallet')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionPallet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def reject_to_repack(multiselect_list)  # rubocop:disable Metrics/AbcSize
      return failed_response('Pallet selection cannot be empty') if multiselect_list.nil_or_empty?

      pallet_ids = repo.selected_pallets(multiselect_list)
      res = nil
      new_pallet_ids = []
      repo.transaction do
        pallet_ids.each do |pallet_id|
          res = FinishedGoodsApp::RepackPallet.call(pallet_id, @user.user_name, true)
          return res unless res.success

          new_pallet_ids << res.instance[:new_pallet_id]
        end
        pallet_numbers = reworks_repo.find_pallet_numbers(pallet_ids)
        res = create_reworks_run(pallet_numbers)
        return res unless res.success

        repo.log_multiple_statuses('pallets', pallet_ids, AppConst::REWORKS_REPACK_PALLET_STATUS)
        repo.log_multiple_statuses('pallet_sequences', reworks_repo.pallet_sequence_ids(pallet_ids), AppConst::REWORKS_REPACK_PALLET_STATUS)
        repo.log_multiple_statuses('pallets', new_pallet_ids, AppConst::REWORKS_REPACK_PALLET_NEW_STATUS)
        repo.log_multiple_statuses('pallet_sequences', reworks_repo.pallet_sequence_ids(new_pallet_ids), AppConst::REWORKS_REPACK_PALLET_STATUS)
      end

      success_response('Selected pallets have been repacked successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
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

    def govt_inspection_pallet(id)
      repo.find_govt_inspection_pallet_flat(id)
    end

    def validate_govt_inspection_pallet_params(params)
      GovtInspectionPalletSchema.call(params)
    end

    def validate_govt_inspection_failed_pallet_params(params)
      GovtInspectionFailedPalletSchema.call(params)
    end

    def reworks_repo
      @reworks_repo ||= ProductionApp::ReworksRepo.new
    end
  end
end
