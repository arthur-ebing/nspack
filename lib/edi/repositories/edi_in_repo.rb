# frozen_string_literal: true

module EdiApp
  class EdiInRepo < BaseRepo
    crud_calls_for :edi_in_transactions, name: :edi_in_transaction, wrapper: EdiInTransaction

    def log_edi_in_complete(id, message)
      update_edi_in_transaction(id, complete: true, error_message: message)
    end

    def log_edi_in_failed(id, message)
      update_edi_in_transaction(id, error_message: message)
    end

    def log_edi_in_error(id, exception)
      update_edi_in_transaction(id, error_message: exception.message)
    end
  end
end
