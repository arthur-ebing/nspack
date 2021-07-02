# frozen_string_literal: true

module Production
  module Runs
    module ReworksRun
      class SearchUntippedBins
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:bulk_tip_bin_process, nil, form_values: form_values)
          rules   = ui_rule.compile
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Search Untipped Bins'
              form.action '/production/reworks/search_untipped_bins'
              form.remote! if remote
              form.add_field :rmt_delivery_id
              form.add_field :puc_id
              form.add_field :orchard_id
              form.add_field :cultivar_id
              form.add_field :from
              form.add_field :to
            end
          end
          layout
        end
      end
    end
  end
end
