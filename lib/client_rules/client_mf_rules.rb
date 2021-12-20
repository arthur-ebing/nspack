# frozen_string_literal: true

module Crossbeams
  class ClientMfRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { calculate_basic_pack_code: false,
            basic_pack_equals_standard_pack: false },
      hl: { calculate_basic_pack_code: false,
            basic_pack_equals_standard_pack: false },
      kr: { calculate_basic_pack_code: true,
            basic_pack_equals_standard_pack: false },
      um: { calculate_basic_pack_code: false,
            basic_pack_equals_standard_pack: true },
      ud: { calculate_basic_pack_code: false,
            basic_pack_equals_standard_pack: false },
      cfg: { calculate_basic_pack_code: false,
             basic_pack_equals_standard_pack: true },
      sr: { calculate_basic_pack_code: false,
            basic_pack_equals_standard_pack: true },
      sr2: { calculate_basic_pack_code: false,
             basic_pack_equals_standard_pack: true }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def kromco_calculate_basic_pack_code?(explain: false)
      return 'Is the client Kromco, then calculate basic_pack_code as footprint_code + height_mm]' if explain

      setting(:calculate_basic_pack_code) && client_code == 'kr'
    end

    def basic_pack_equals_standard_pack?(explain: false)
      return 'Creating a standard pack will automatically create a basic pack and only allow one Standard pack per Basic pack' if explain

      setting(:basic_pack_equals_standard_pack)
    end
  end
end
