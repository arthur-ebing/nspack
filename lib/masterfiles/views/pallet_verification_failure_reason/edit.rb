# frozen_string_literal: true

module Masterfiles
  module Quality
    module PalletVerificationFailureReason
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:pallet_verification_failure_reason, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Pallet Verification Failure Reason'
              form.action "/masterfiles/quality/pallet_verification_failure_reasons/#{id}"
              form.remote!
              form.method :update
              form.add_field :reason
            end
          end

          layout
        end
      end
    end
  end
end
