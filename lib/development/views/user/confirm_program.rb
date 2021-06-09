# frozen_string_literal: true

module Development
  module Masterfiles
    module User
      class ConfirmProgram
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:user, :new, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_grid('user_program_permissions',
                               "/list/user_program_permissions/grid?key=standard&id=#{form_values[:from_user_id]}",
                               caption: 'Program permissions')
            end
            page.form do |form|
              form.action "/development/masterfiles/users/#{id}/copy_programs"
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
