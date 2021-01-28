# frozen_string_literal: true

module Crossbeams
  class ClientMfRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { calculate_basic_pack_code: false },
      hl: { calculate_basic_pack_code: false },
      kr: { calculate_basic_pack_code: true },
      um: { calculate_basic_pack_code: false },
      ud: { calculate_basic_pack_code: false },
      sr: { calculate_basic_pack_code: false },
      sr2: { calculate_basic_pack_code: false }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def kromco_calculate_basic_pack_code?(explain: false)
      return 'Is the client Kromco, then calculate basic_pack_code as footprint_code + height_mm]' if explain

      setting(:calculate_basic_pack_code) && client_code == 'kr'
    end
  end
end
