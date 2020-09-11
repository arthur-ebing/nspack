# frozen_string_literal: true

module DevelopmentApp
  ScaffoldNewSchema = Dry::Schema.Params do
    required(:table).filled(:string)
    optional(:other).maybe(Types::StrippedString)
    required(:program).filled(Types::StrippedString)
    required(:label_field).maybe(Types::StrippedString)
    required(:short_name).filled(Types::StrippedString)
    required(:shared_repo_name).maybe(Types::StrippedString)
    required(:shared_factory_name).maybe(Types::StrippedString)
    required(:nested_route_parent).maybe(:string)
    required(:new_from_menu).maybe(:bool)
    required(:jobs).maybe(:string)
    required(:services).maybe(:string)

    # FIXME: Dry-update
    # required(:applet).filled(:string).when(eql?: 'other') do
    #   value(:other).filled?
    # end
  end
end
