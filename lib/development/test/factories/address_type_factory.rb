# frozen_string_literal: true

module DevelopmentApp
  module AddressTypeFactory
    def create_address_type(opts = {})
      default = {
        address_type: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:address_types].insert(default.merge(opts))
    end
  end
end
