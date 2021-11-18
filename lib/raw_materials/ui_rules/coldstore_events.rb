# frozen_string_literal: true

module UiRules
  class ColdstoreEventsRule < Base
    def generate_rules
      repo = RawMaterialsApp::LocationRepo.new
      rules[:rows], rules[:cols], rules[:header_captions] = repo.coldroom_events_for_bin(@options[:id])
    end
  end
end
