# frozen_string_literal: true

module Masterfiles
  module Quality
    module Inspector
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:inspector, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Inspector'
              form.action '/masterfiles/quality/inspectors'
              form.remote! if remote
              form.add_field :inspector_party_role_id
              form.add_field :tablet_ip_address
              form.add_field :tablet_port_number
            end
          end

          layout
        end
      end
    end
  end
end
