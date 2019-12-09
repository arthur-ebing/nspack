# frozen_string_literal: true

module EdiApp
  class EdiOutRepo < BaseRepo
    crud_calls_for :edi_out_transactions, name: :edi_out_transaction, wrapper: EdiOutTransaction

    def create_edi_out_transaction(flow_type, org_code, user_name, record_id, hub_address)
      DB[:edi_out_transactions].insert(flow_type: flow_type,
                                       org_code: org_code,
                                       user_name: user_name,
                                       hub_address: hub_address,
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

    def hub_address_for_po(id)
      hub_address = DB[:loads]
                    .join(:depots, id: :depot_id)
                    .where(Sequel[:loads][:id] => id)
                    .get(:edi_hub_address)
      raise Crossbeams::FrameworkError, "There is no EDI out hub address for load with id '#{id}'" if hub_address.nil?

      hub_address
    end

    def hub_address_for_ps(org_code)
      hub_address = DB[:organizations].where(short_description: org_code).get(:edi_hub_address)
      raise Crossbeams::FrameworkError, "There is no EDI out hub address for org '#{org_code}'" if hub_address.nil?

      hub_address
    end
  end
end
