# frozen_string_literal: true

module EdiApp
  class EdiOutRepo < BaseRepo
    crud_calls_for :edi_out_transactions, name: :edi_out_transaction, wrapper: EdiOutTransaction

    def create_edi_out_transaction(flow_type, org_code, user_name, record_id)
      DB[:edi_out_transactions].insert(flow_type: flow_type,
                                       org_code: org_code,
                                       user_name: user_name,
                                       hub_address: AppConst::EDI_HUB_ADDRESS,
                                       record_id: record_id)
    end

    def log_edi_out_complete(id, edi_filename)
      update_edi_out_transaction(id, complete: true, edi_out_filename: edi_filename)
    end

    def log_edi_out_failed(id, message)
      update_edi_out_transaction(id, error_message: message)
    end

    def log_edi_out_error(id, exception)
      update_edi_out_transaction(id, error_message: exception.message)
    end

    def new_sequence_for_flow(flow_type)
      next_document_sequence_number("edi_out_#{flow_type.downcase}")
    end
  end
end
