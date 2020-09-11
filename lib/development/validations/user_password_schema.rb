# frozen_string_literal: true

module DevelopmentApp
  UserPasswordSchema = Dry::Schema.Params do
    required(:password).filled(Types::StrippedString, min_size?: 4)
    required(:password_confirmation).filled(Types::StrippedString, min_size?: 4)

    # FIXME: Dry-update
    # rule(password_confirmation: [:password]) do |password|
    #   value(:password_confirmation).eql?(password)
    # end
  end
end
