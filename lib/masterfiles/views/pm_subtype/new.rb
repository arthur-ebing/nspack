# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmSubtype
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_subtype, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New PM Subtype'
              form.action '/masterfiles/packaging/pm_subtypes'
              form.remote! if remote
              form.add_field :pm_type_id
              form.add_field :subtype_code
              form.add_field :short_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
