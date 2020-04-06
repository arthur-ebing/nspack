# frozen_string_literal: true

module FinishedGoods
  module Ecert
    module EcertTrackingUnit
      class Status
        def self.call(res: nil, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:ecert_tracking_unit_status, :new, res: res, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'eCert Tracking Unit Status'
              form.action '/finished_goods/ecert/ecert_tracking_units/status'
              form.remote! if remote
              form.add_field :pallet_number
            end
            page.section do |section|
              unless res.nil?
                section.add_diff :header
                section.add_diff :diff
              end
            end
          end

          layout
        end
      end
    end
  end
end
