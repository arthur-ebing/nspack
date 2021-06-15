# frozen_string_literal: true

module ProductionApp
  class BulkBinTippingStep < BaseStep
    def initialize(key, user, ip)
      super(user, key, ip)
    end
  end
end
