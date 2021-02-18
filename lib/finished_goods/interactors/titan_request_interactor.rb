# frozen_string_literal: true

module FinishedGoodsApp
  class TitanRequestInteractor < BaseInteractor
    def delete_titan_request(id)
      name = titan_request(id).request_type
      repo.transaction do
        repo.delete_titan_request(id)
        log_transaction
      end
      success_response("Deleted titan request #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete titan request. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::TitanRequest.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= TitanRepo.new
    end

    def titan_request(id)
      repo.find_titan_request(id)
    end
  end
end
