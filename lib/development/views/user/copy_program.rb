# frozen_string_literal: true

module Development
  module Masterfiles
    module User
      class CopyProgram
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:user, :new, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/development/masterfiles/users/#{id}/confirm_programs"
              form.remote!
              form.method :update
              form.add_field :from_user_id
            end
          end

          layout
        end
      end
    end
  end
end
