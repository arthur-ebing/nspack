# frozen_string_literal: true

module Quality
  module Mrl
    module MrlResult
      class Override
        def self.call(id, attrs, button_captions: ['Submit', 'Submitting...'], remote: true)
          ui_rule = UiRules::Compiler.new(:mrl_result, :override, form_values: nil, id: id, attrs: attrs)
          rules   = ui_rule.compile

          notice = if rules[:no_changes_made]
                     'No changes were made'
                   else
                     'Press the button to override mrl result'
                   end
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_diff :changes_made
            end
            page.form do |form|
              form.action "/quality/mrl/mrl_results/#{id}/override_mrl_result"
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
