# frozen_string_literal: true

module FinishedGoodsApp
  module VoyagePortFactory
    def create_voyage_port(opts = {})
      voyage_id = create_voyage
      port_id = create_port
      vessel_id = create_vessel

      default = {
        voyage_id: voyage_id,
        port_id: port_id,
        trans_shipment_vessel_id: vessel_id,
        ata: '2010-01-01',
        atd: '2010-01-01',
        eta: '2010-01-01',
        etd: '2010-01-01',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:voyage_ports].insert(default.merge(opts))
    end

    def create_voyage(opts = {})
      vessel_id = create_vessel

      default = {
        vessel_id: vessel_id,
        voyage_type_id: 1,
        voyage_number: Faker::Lorem.unique.word,
        voyage_code: Faker::Lorem.unique.word,
        year: Faker::Number.number(4),
        completed: false,
        completed_at: '2010-01-01 12:00',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:voyages].insert(default.merge(opts))
    end

    def create_vessel(opts = {})
      vessel_type_id = create_vessel_type

      default = {
        vessel_type_id: vessel_type_id,
        vessel_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vessels].insert(default.merge(opts))
    end

    def create_vessel_type(opts = {})
      default = {
        voyage_type_id: 1,
        vessel_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vessel_types].insert(default.merge(opts))
    end

    def create_port(opts = {})
      default = {
        port_type_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        voyage_type_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        port_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:ports].insert(default.merge(opts))
    end
  end
end
