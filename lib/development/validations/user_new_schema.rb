# frozen_string_literal: true

module DevelopmentApp
  UserNewSchema = Dry::Schema.Params do
    required(:login_name).filled(Types::StrippedString, min_size?: 3, format?: /\A[[:print:]]+\Z/)
    required(:user_name).filled(Types::StrippedString)
    required(:password).filled(Types::StrippedString, min_size?: 4)
    required(:password_confirmation).filled(Types::StrippedString, min_size?: 4)
    required(:email).maybe(Types::StrippedString)

    # FIXME: Dry-update
    # rule(password_confirmation: [:password]) do |password|
    #   value(:password_confirmation).eql?(password)
    # end
  end
end
