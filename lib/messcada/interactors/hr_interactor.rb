# frozen_string_literal: true

module MesscadaApp
  class HrInteractor < BaseInteractor
    def register_identifier(params) # rubocop:disable Metrics/AbcSize
      res = validate_identifier_for_registration(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_personnel_identifier(res)
        log_status(:personnel_identifiers, id, 'CREATED')
        log_transaction
      end
      success_response("Created personnel identifier #{res[:value]}")
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('register_identifier'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= HrRepo.new
    end

    def validate_identifier_for_registration(params)
      RegisterIdentifierSchema.call(params)
    end
  end
end
