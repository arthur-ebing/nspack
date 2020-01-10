# frozen_string_literal: true

module Edi
  module Actions
    module Send
      class PS
        def self.call
          ui_rule = UiRules::Compiler.new(:edi_actions, :send_ps)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.action '/edi/actions/send_ps'
              form.add_notice 'Press the button to generate and send a PS EDI'
              form.add_field :party_role_id
            end
          end

          layout
        end
      end
    end
  end
end
