# frozen_string_literal: true

module FinishedGoods
  module Ecert
    module EcertTrackingUnit
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:ecert_tracking_unit, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :pallet_id
              form.add_field :ecert_agreement_id
              form.add_field :business_id
              form.add_field :industry
              form.add_field :elot_key
              form.add_field :verification_key
              form.add_field :passed
              form.add_field :process_result
              form.add_field :rejection_reasons
            end
          end

          layout
        end
      end
    end
  end
end
