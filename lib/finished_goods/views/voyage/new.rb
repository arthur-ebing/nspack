# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Voyage
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:voyage, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Voyage'
              form.action '/finished_goods/dispatch/voyages'
              form.remote! if remote
              form.add_field :voyage_type_id
              form.add_field :vessel_id
              form.add_field :voyage_number
              form.add_field :voyage_code
              form.add_field :year
              form.add_field :completed
              form.add_field :completed_at
            end
          end

          layout
        end
      end
    end
  end
end
