# frozen_string_literal: true

module FinishedGoodsApp
  module EcertAgreementFactory
    def create_ecert_agreement(opts = {})
      default = {
        code: Faker::Lorem.unique.word,
        name: Faker::Lorem.word,
        description: Faker::Lorem.word,
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:ecert_agreements].insert(default.merge(opts))
    end
  end
end
