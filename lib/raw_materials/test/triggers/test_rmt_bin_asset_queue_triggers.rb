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
      skip 'todo'
      # bin with delivery_id set
      # change the rmt_material_owner_party_role_id
    end

    def test_change_type_of_delivery_bin
      skip 'todo'
      # bin with delivery_id set
      # change the rmt_container_material_type_id
    end

    def test_change_all_of_delivery_bin
      skip 'todo'
      # bin with delivery_id set
      # change the farm_id
      # change the rmt_material_owner_party_role_id
      # change the rmt_container_material_type_id
    end

    def test_change_non_trigger_fields
      skip 'todo'
      # create a bin
      # change a few fields that should not trigger
      # Check that no extra queue records were added
    end

    def test_change_farm_of_prodrun_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id set
      # change the farm_id
    end

    def test_change_owner_of_prodrun_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id set
      # change the rmt_material_owner_party_role_id
    end

    def test_change_type_of_prodrun_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id set
      # change the rmt_container_material_type_id
    end

    def test_change_all_of_prodrun_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id set
      # change the farm_id
      # change the rmt_material_owner_party_role_id
      # change the rmt_container_material_type_id
    end

    def test_change_farm_of_plain_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id null, is_rebin: true
      # change the farm_id
    end

    def test_change_owner_of_plain_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id null, is_rebin: true
      # change the rmt_material_owner_party_role_id
    end

    def test_change_type_of_plain_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id null, is_rebin: true
      # change the rmt_container_material_type_id
    end

    def test_change_all_of_plain_rebin_bin
      skip 'todo'
      # bin with delivery_id null, production_run_rebin_id null, is_rebin: true
      # change the farm_id
      # change the rmt_material_owner_party_role_id
      # change the rmt_container_material_type_id
    end

    def test_change_tipped_of_delivered_bin
      skip 'todo'
      # Any kind of bin
      # Change bin_tipped to true and to false
    end

    def test_change_scrapped_of_delivered_bin
      skip 'todo'
      # Any kind of bin
      # Change scrapped to true and to false
    end

    def test_change_shipped_asset_of_delivered_bin
      skip 'todo'
      # Any kind of bin
      # Change shipped_asset_number to a value and to null
    end
  end
end
