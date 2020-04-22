# frozen_string_literal: true

module EdiApp
  class EdiInTransactionInteractor < BaseInteractor
    private

    def repo
      @repo ||= EdiInTransactionRepo.new
    end
  end
end
