# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationItemInteractor < BaseInteractor
    def refresh_packing_specification_items
      repo.transaction do
        repo.refresh_packing_specification_items(@user)
        log_transaction
      end
      success_response('Created packing specification items')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_packing_specification_item(params) # rubocop:disable Metrics/AbcSize
      res = validate_packing_specification_item_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_packing_specification_item(res)
        FinishedGoodsApp::Job::CalculateExtendedFgCodesForPackingSpecs.enqueue([id]) if AppConst::CR_FG.lookup_extended_fg_code?
        check!(:duplicates, id)

        log_status(:packing_specification_items, id, 'CREATED')
        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("Created packing specification item #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This packing specification item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_packing_specification_item(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_packing_specification_item_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_packing_specification_item(id, res)
        FinishedGoodsApp::Job::CalculateExtendedFgCodesForPackingSpecs.enqueue([id]) if AppConst::CR_FG.lookup_extended_fg_code?
        check!(:duplicates, id)

        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("Updated packing specification item #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def inline_update_packing_specification_item(id, params)
      repo.transaction do
        repo.inline_update_packing_specification_item(id, params)
        check!(:duplicates, id)

        log_transaction
      end

      instance = packing_specification_item(id)
      success_response('Updated packing specification item', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_packing_specification_item(id) # rubocop:disable Metrics/AbcSize
      name = packing_specification_item(id).description
      repo.transaction do
        repo.delete_packing_specification_item(id)
        log_status(:packing_specification_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted packing specification item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete packing specification item. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PackingSpecificationItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def check!(task, id = nil)
      res = TaskPermissionCheck::PackingSpecificationItem.call(task, id)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def packing_specification_item(id)
      repo.find_packing_specification_item(id)
    end

    def for_select_pm_marks(where: {})
      MasterfilesApp::BomRepo.new.for_select_pm_marks(where: where).map { |row| row[0] }.unshift('')
    end

    def for_select_packing_spec_pm_boms(where: {})
      MasterfilesApp::BomRepo.new.for_select_packing_spec_pm_boms(where: where).map { |row| row[0] }.unshift('')
    end

    private

    def repo
      @repo ||= PackingSpecificationRepo.new
    end

    def validate_packing_specification_item_params(params)
      params[:fruit_sticker_ids] ||= []
      params[:tu_sticker_ids] ||= []
      params[:ru_sticker_ids] ||= []
      PackingSpecificationItemSchema.call(params)
    end
  end
end
