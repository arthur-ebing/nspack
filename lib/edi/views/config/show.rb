# frozen_string_literal: true

module Edi
  module Config
    module EdiOutRule
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:edi_out, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Edi Out Rule'
              form.view_only!
              form.add_field :flow_type
              form.add_field :depot_id
              form.add_field :role_id
              form.add_field :party_role_id
              form.add_field :hub_address
              form.add_field :directory_keys
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
