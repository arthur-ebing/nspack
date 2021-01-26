# frozen_string_literal: true

module DevelopmentApp
  module ContactMethodTypeFactory
    def create_contact_method_type(opts = {})
      default = {
        contact_method_type: Faker::Lorem.unique.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        active: true
      }
      DB[:contact_method_types].insert(default.merge(opts))
    end
  end
end
