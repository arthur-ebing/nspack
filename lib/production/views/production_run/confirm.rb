# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class Confirm
        def self.call(id, url: nil, notice: nil, error: nil, button_captions: ['Submit', 'Submitting...'], remote: true)
          ui_rule = UiRules::Compiler.new(:production_run, :confirm, form_values: nil, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action url
              form.remote! if remote
              form.add_notice notice, show_caption: false unless error
              form.add_notice error, show_caption: false, notice_type: :error if error
              form.no_submit! if error
              form.submit_captions(*button_captions)
            end
          end
        end
      end
    end
  end
end
