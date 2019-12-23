# frozen_string_literal: true

module EdiApp
  EdiFileUploadSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:flow_type, Types::StrippedString).filled(:str?)
    # required(:edi_file, :file).filled(max_file_size?: 2.megabytes, allowable_file_type?: ['text/plain', 'text/csv'])
    # required(:edi_file, :file).filled
  end
end
