# frozen_string_literal: true

module Masterfiles
  module Finance
    module PaymentTermDateType
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:payment_term_date_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Payment Term Date Type'
              form.view_only!
              form.add_field :type_of_date
              form.add_field :no_days_after_etd
              form.add_field :no_days_after_eta
              form.add_field :no_days_after_atd
              form.add_field :no_days_after_ata
              form.add_field :no_days_after_invoice
              form.add_field :no_days_after_invoice_sent
              form.add_field :no_days_after_container_load
              form.add_field :anchor_to_date
              form.add_field :adjust_anchor_date_to_month_end
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
