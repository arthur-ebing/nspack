# frozen_string_literal: true

class Nspack < Roda
  route 'receipts', 'edi' do |r|
    # EDI IN TRANSACTIONS
    # --------------------------------------------------------------------------
    r.on 'edi_in_transactions', Integer do |id|
      interactor = EdiApp::EdiInTransactionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:edi_in_transactions, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('receipts', 'read')
          show_partial { Edi::Receipts::EdiInTransaction::Show.call(id) }
        end
      end
    end
  end
end
