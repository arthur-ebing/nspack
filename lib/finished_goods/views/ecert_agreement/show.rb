# frozen_string_literal: true

module FinishedGoods
  module Ecert
    module EcertAgreement
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:ecert_agreement, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'eCert Agreement'
              form.view_only!
              form.add_field :code
              form.add_field :name
              form.add_field :description
              form.add_field :start_date
              form.add_field :end_date
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
