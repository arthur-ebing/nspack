# frozen_string_literal: true

module MesscadaApp
  # Find the identifier for a logged-in worker if not included in the parameters.
  class AddIdentifierToLoginWithNo < BaseService
    attr_reader :params, :repo

    def initialize(params)
      super()
      @params = params
      @repo = HrRepo.new
    end

    def call # rubocop:disable Metrics/AbcSize
      return success_response('ok', params) unless params[:identifier].nil_or_empty?

      contract_worker_id = repo.logged_in_worker_for_device(params[:device], params[:card_reader])
      return failed_response('Not logged-in', params) if contract_worker_id.nil?

      identifier = repo.identifier_from_contract_worker_id(contract_worker_id)
      return failed_response('No identifier for login', params) if identifier.nil?

      success_response('ok', params.merge(identifier: identifier))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: "#{self.class.name} : #{e.message}", message: <<~STR)
        params: #{params.inspect}

        #{e.message}
      STR
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end
  end
end
