# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class ProductionRuns
        def self.call(params)
          qstr = if params[:line]
                   "?line=#{params[:line]}"
                 else
                   ''
                 end
          line = if params[:line]
                   " on #{params[:line]}"
                 else
                   ''
                 end
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text "Production runs#{line}", wrapper: :h2
            page.add_repeating_request "/production/dashboards/production_runs/detail#{qstr}", 5000, ''
          end

          layout
        end
      end
    end
  end
end
