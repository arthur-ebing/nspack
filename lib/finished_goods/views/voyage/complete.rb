# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Voyage
      class Complete
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:voyage, :complete, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              page.form_values form_values
              page.form_errors form_errors
              form.caption 'Complete Voyage'
              form.action "/finished_goods/dispatch/voyages/#{id}/complete"
              form.remote!
              form.submit_captions 'Complete'
              form.add_text 'Are you sure you want to complete this voyage?', wrapper: :h3
              form.add_field :to
              form.add_field :vessel_id
              form.add_field :voyage_type_id
              form.add_field :voyage_number
              form.add_field :voyage_code
              form.add_field :year
              form.add_field :completed
              form.add_field :completed_at
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
