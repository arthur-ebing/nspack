# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingPool
      class Confirm
        def self.call(id, url: nil, notice: nil, button_captions: ['Submit', 'Submitting...'], remote: true)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_pool, :confirm, form_values: nil, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action url
              form.remote! if remote
              form.add_notice notice, show_caption: false
              form.submit_captions(*button_captions)
            end
          end

          layout
        end
      end
    end
  end
end
