# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class SelectLabelLine
        def self.call
          ui_rule = UiRules::Compiler.new(:production_run_select, :select_label_run)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Active labeling setups for line'
              form.submit_captions 'Select'
              form.action '/production/in_progress/product_setups/select'
              if rules[:notice]
                form.add_notice rules[:notice]
                form.no_submit!
              else
                form.inline!
              end
              form.add_field :production_run_id
            end
          end

          layout
        end
      end
    end
  end
end
