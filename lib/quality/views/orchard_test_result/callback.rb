# frozen_string_literal: true

module Quality
  module TestResults
    module OrchardTestResult
      class Callback
        def self.call(remaining_path)
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.callback_section do |section|
              section.caption = 'Fetching Phytclean results'
              section.url = "/quality/test_results/orchard_test_results#{remaining_path}"
            end
          end

          layout
        end
      end
    end
  end
end
