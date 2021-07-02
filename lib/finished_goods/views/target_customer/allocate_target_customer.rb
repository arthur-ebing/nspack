# frozen_string_literal: true

module FinishedGoods
  module Stock
    module TargetCustomer
      class AllocateTargetCustomer
        def self.call
          ui_rule = UiRules::Compiler.new(:target_customer, :new)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Allocate target customer'
              form.submit_captions 'Select'
              form.action '/finished_goods/stock/allocate_target_customer/new'
              if rules[:notice]
                form.add_notice rules[:notice]
                form.no_submit!
              else
                form.inline!
              end
              form.add_field :target_customer_party_role_id
            end
          end

          layout
        end
      end
    end
  end
end
