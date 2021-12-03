# frozen_string_literal: true

module FinishedGoodsApp
  class InspectionInteractor < BaseInteractor
    def create_inspection(params)
      res = InspectionPalletSchema.call(params)
      return validation_failed_response(res) if res.failure?

      ids = nil
      repo.transaction do
        ids = repo.create_inspection(res)
        log_multiple_statuses(:inspections, ids, 'CREATED')
        log_transaction
      end
      return failed_response('No inspections defined for pallet.') if ids.nil_or_empty?

      success_response('Created inspections', get_pallet_id(res))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_inspection(id, params)
      res = validate_inspection_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inspection(id, res)
        log_status(:inspections, id, 'INSPECTED')
        log_transaction
      end
      instance = inspection(id)
      success_response("Updated inspection #{instance.inspection_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inspection(id)
      name = inspection(id).inspection_type_code
      repo.transaction do
        repo.delete_inspection(id)
        log_status(:inspections, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inspection #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete inspection. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Inspection.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def pallet_inspection_status(params) # rubocop:disable Metrics/AbcSize
      res = InspectionPalletSchema.call(params)
      return validation_failed_response(res) if res.failure?

      pallet_number = res[:pallet_number]
      res = MesscadaApp::TaskPermissionCheck::Pallet.call(%i[exists not_scrapped not_shipped], pallet_number: pallet_number)
      return res unless res.success

      insp_res = nil
      repo.transaction do
        insp_res = FinishedGoodsApp::FailedAndPendingPalletInspections.call(pallet_number, check_status: true)
        unless insp_res.success
          instance = OpenStruct.new(failed_inspections: insp_res[:errors][:failed].join(','),
                                    pending_inspections: insp_res[:errors][:pending].join(','))
          return failed_response(insp_res.message, instance)
        end
      end
      insp_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= InspectionRepo.new
    end

    def inspection(id)
      repo.find_inspection(id)
    end

    def validate_inspection_params(params)
      InspectionContract.new.call(params)
    end

    def get_pallet_id(res)
      repo.get_id(:pallets, pallet_number: res.to_h[:pallet_number])
    end
  end
end
