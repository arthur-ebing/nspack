# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestRmtBinAssetQueueTriggers < MiniTestWithHooks
    include BinLoadFactory
    include RmtBinFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::RmtContainerFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::LocationFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductSetupFactory

    class QueueEntity < Dry::Struct
      attribute :id, Types::Integer
      attribute :rmt_bin_id, Types::Integer
      attribute :bin_event_type, Types::String
      attribute :pallet, Types::Bool
      attribute :changes_made, Types::Hash
    end

    def entity(hash)
      QueueEntity.new(hash)
    end

    def match_changes(expect, queue)
      assert_equal expect.tr(' ', ''), JSON.parse(queue.changes_made.to_json, symbolize_names: true).tr(' ', ''), "Called from: #{caller[0, 1].first}"
    end

    def test_add_and_delete_delivery_bin
      delivery_id = create_rmt_delivery
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).delete
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'BIN_DELETED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made
    end

    def test_add_and_delete_production_rebin_bin
      prodrun_id = create_production_run
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: prodrun_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).delete
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_DELETED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made
    end

    def test_add_and_delete_default_rebin_bin
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: nil, is_rebin: true)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).delete
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_DELETED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made
    end

    def test_change_farm_of_delivery_bin
      delivery_id = create_rmt_delivery
      farm1_id = create_farm
      farm2_id = create_farm(force_create: true)
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, farm_id: farm1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(farm_id: farm2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'FARM_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { farm_id: #{farm1_id} }, after: { farm_id: #{farm2_id} } }"
      match_changes(expect, queue)
    end

    def test_change_owner_of_delivery_bin
      delivery_id = create_rmt_delivery
      rmt_container_material_type_id = create_rmt_container_material_type
      rmt_material_owner_party_role1_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_material_owner_party_role2_id = create_party_role(party_type: 'O', name: AppConst::ROLE_RMT_BIN_OWNER)
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, rmt_container_material_type_id: rmt_container_material_type_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(rmt_material_owner_party_role_id: rmt_material_owner_party_role2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role1_id},
                            rmt_container_material_type_id: #{rmt_container_material_type_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role2_id},
                           rmt_container_material_type_id: #{rmt_container_material_type_id} } }"
      match_changes(expect, queue)
    end

    def test_change_type_of_delivery_bin
      delivery_id = create_rmt_delivery
      rmt_material_owner_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_container_material_type1_id = create_rmt_container_material_type
      rmt_container_material_type2_id = create_rmt_container_material_type(force_create: true)
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, rmt_container_material_type_id: rmt_container_material_type1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(rmt_container_material_type_id: rmt_container_material_type2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role_id},
                            rmt_container_material_type_id: #{rmt_container_material_type1_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role_id},
                           rmt_container_material_type_id: #{rmt_container_material_type2_id} } }"
      match_changes(expect, queue)
    end

    def test_change_all_of_delivery_bin
      delivery_id = create_rmt_delivery
      farm1_id = create_farm
      farm2_id = create_farm(force_create: true)

      rmt_material_owner_party_role1_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_material_owner_party_role2_id = create_party_role(party_type: 'O', name: AppConst::ROLE_RMT_BIN_OWNER)

      rmt_container_material_type1_id = create_rmt_container_material_type
      rmt_container_material_type2_id = create_rmt_container_material_type(force_create: true)

      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, farm_id: farm1_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role1_id, rmt_container_material_type_id: rmt_container_material_type1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(farm_id: farm2_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role2_id, rmt_container_material_type_id: rmt_container_material_type2_id)
      assert_equal 3, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id

      assert_equal 'MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role1_id},
                            rmt_container_material_type_id: #{rmt_container_material_type1_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role2_id},
                           rmt_container_material_type_id: #{rmt_container_material_type2_id} } }"
      match_changes(expect, queue)
    end

    def test_change_non_trigger_fields
      delivery_id = create_rmt_delivery
      farm_id = create_farm
      location1_id = create_location
      location2_id = create_location(force_create: true)
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, farm_id: farm_id, location_id: location1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(location_id: location2_id)
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      refute queue.pallet
    end

    def test_change_farm_of_prodrun_rebin_bin
      prodrun_id = create_production_run
      farm1_id = create_farm
      farm2_id = create_farm(force_create: true)
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: prodrun_id, farm_id: farm1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(farm_id: farm2_id)
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      refute queue.pallet
    end

    def test_change_owner_of_prodrun_rebin_bin
      prodrun_id = create_production_run
      rmt_container_material_type_id = create_rmt_container_material_type
      rmt_material_owner_party_role1_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_material_owner_party_role2_id = create_party_role(party_type: 'O', name: AppConst::ROLE_RMT_BIN_OWNER)
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: prodrun_id, rmt_container_material_type_id: rmt_container_material_type_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(rmt_material_owner_party_role_id: rmt_material_owner_party_role2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role1_id},
                            rmt_container_material_type_id: #{rmt_container_material_type_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role2_id},
                           rmt_container_material_type_id: #{rmt_container_material_type_id} } }"
      match_changes(expect, queue)
    end

    def test_change_type_of_prodrun_rebin_bin
      prodrun_id = create_production_run
      rmt_material_owner_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_container_material_type1_id = create_rmt_container_material_type
      rmt_container_material_type2_id = create_rmt_container_material_type(force_create: true)
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: prodrun_id, rmt_container_material_type_id: rmt_container_material_type1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(rmt_container_material_type_id: rmt_container_material_type2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role_id},
                            rmt_container_material_type_id: #{rmt_container_material_type1_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role_id},
                           rmt_container_material_type_id: #{rmt_container_material_type2_id} } }"
      match_changes(expect, queue)
    end

    def test_change_all_of_prodrun_rebin_bin
      prodrun_id = create_production_run
      farm1_id = create_farm
      farm2_id = create_farm(force_create: true)

      rmt_material_owner_party_role1_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_material_owner_party_role2_id = create_party_role(party_type: 'O', name: AppConst::ROLE_RMT_BIN_OWNER)

      rmt_container_material_type1_id = create_rmt_container_material_type
      rmt_container_material_type2_id = create_rmt_container_material_type(force_create: true)

      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: prodrun_id, farm_id: farm1_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role1_id, rmt_container_material_type_id: rmt_container_material_type1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(farm_id: farm2_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role2_id, rmt_container_material_type_id: rmt_container_material_type2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id

      assert_equal 'REBIN_MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role1_id},
                            rmt_container_material_type_id: #{rmt_container_material_type1_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role2_id},
                           rmt_container_material_type_id: #{rmt_container_material_type2_id} } }"
      match_changes(expect, queue)
    end

    def test_change_farm_of_plain_rebin_bin
      farm1_id = create_farm
      farm2_id = create_farm(force_create: true)
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: nil, farm_id: farm1_id, is_rebin: true)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(farm_id: farm2_id)
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      refute queue.pallet
    end

    def test_change_owner_of_plain_rebin_bin
      rmt_container_material_type_id = create_rmt_container_material_type
      rmt_material_owner_party_role1_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_material_owner_party_role2_id = create_party_role(party_type: 'O', name: AppConst::ROLE_RMT_BIN_OWNER)
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: nil, is_rebin: true, rmt_container_material_type_id: rmt_container_material_type_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(rmt_material_owner_party_role_id: rmt_material_owner_party_role2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role1_id},
                            rmt_container_material_type_id: #{rmt_container_material_type_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role2_id},
                           rmt_container_material_type_id: #{rmt_container_material_type_id} } }"
      match_changes(expect, queue)
    end

    def test_change_type_of_plain_rebin_bin
      rmt_material_owner_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_container_material_type1_id = create_rmt_container_material_type
      rmt_container_material_type2_id = create_rmt_container_material_type(force_create: true)
      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: nil, is_rebin: true, rmt_container_material_type_id: rmt_container_material_type1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(rmt_container_material_type_id: rmt_container_material_type2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role_id},
                            rmt_container_material_type_id: #{rmt_container_material_type1_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role_id},
                           rmt_container_material_type_id: #{rmt_container_material_type2_id} } }"
      match_changes(expect, queue)
    end

    def test_change_all_of_plain_rebin_bin
      farm1_id = create_farm
      farm2_id = create_farm(force_create: true)

      rmt_material_owner_party_role1_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_material_owner_party_role2_id = create_party_role(party_type: 'O', name: AppConst::ROLE_RMT_BIN_OWNER)

      rmt_container_material_type1_id = create_rmt_container_material_type
      rmt_container_material_type2_id = create_rmt_container_material_type(force_create: true)

      bin_id = create_rmt_bin(rmt_delivery_id: nil, production_run_rebin_id: nil, is_rebin: true, farm_id: farm1_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role1_id, rmt_container_material_type_id: rmt_container_material_type1_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'REBIN_CREATED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(farm_id: farm2_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role2_id, rmt_container_material_type_id: rmt_container_material_type2_id)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id

      assert_equal 'REBIN_MATERIAL_OWNER_CHANGED', queue.bin_event_type
      refute queue.pallet
      expect = "{ before: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role1_id},
                            rmt_container_material_type_id: #{rmt_container_material_type1_id} },
                  after: { rmt_material_owner_party_role_id: #{rmt_material_owner_party_role2_id},
                           rmt_container_material_type_id: #{rmt_container_material_type2_id} } }"
      match_changes(expect, queue)
    end

    def test_change_tipped_of_delivered_bin
      delivery_id = create_rmt_delivery
      farm_id = create_farm
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, farm_id: farm_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(bin_tipped: true)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'BIN_TIPPED', queue.bin_event_type
      refute queue.pallet
      expect = '{ before: { bin_tipped: false }, after: { bin_tipped: true } }'
      match_changes(expect, queue)

      DB[:rmt_bins].where(id: bin_id).update(bin_tipped: false)
      assert_equal 3, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'BIN_UNTIPPED', queue.bin_event_type
      refute queue.pallet
      expect = '{ before: { bin_tipped: true }, after: { bin_tipped: false } }'
      match_changes(expect, queue)
    end

    def test_change_scrapped_of_delivered_bin
      delivery_id = create_rmt_delivery
      farm_id = create_farm
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, farm_id: farm_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(scrapped: true)
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'BIN_SCRAPPED', queue.bin_event_type
      refute queue.pallet
      expect = '{ before: { scrapped: false }, after: { scrapped: true } }'
      match_changes(expect, queue)

      DB[:rmt_bins].where(id: bin_id).update(scrapped: false)
      assert_equal 3, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'BIN_UNSCRAPPED', queue.bin_event_type
      refute queue.pallet
      expect = '{ before: { scrapped: true }, after: { scrapped: false } }'
      match_changes(expect, queue)
    end

    def test_change_shipped_asset_of_delivered_bin
      delivery_id = create_rmt_delivery
      farm_id = create_farm
      bin_id = create_rmt_bin(rmt_delivery_id: delivery_id, production_run_rebin_id: nil, farm_id: farm_id)
      refute_nil bin_id
      assert_equal 1, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'DELIVERY_RECEIVED', queue.bin_event_type
      refute queue.pallet
      assert_nil queue.changes_made

      DB[:rmt_bins].where(id: bin_id).update(shipped_asset_number: 'shipped')
      assert_equal 2, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'BIN_DISPATCHED_VIA_RMT', queue.bin_event_type
      refute queue.pallet

      DB[:rmt_bins].where(id: bin_id).update(shipped_asset_number: nil)
      assert_equal 3, DB[:bin_asset_transactions_queue].count
      queue = entity(DB[:bin_asset_transactions_queue].reverse(:id).first)
      assert_equal bin_id, queue.rmt_bin_id
      assert_equal 'BIN_UNSHIPPED', queue.bin_event_type
      refute queue.pallet
    end
  end
end
