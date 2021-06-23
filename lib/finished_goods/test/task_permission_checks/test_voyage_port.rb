# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestVoyagePortPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        voyage_id: 1,
        port_id: 1,
        trans_shipment_vessel_id: 1,
        ata: '2010-01-01',
        atd: '2010-01-01',
        eta: '2010-01-01',
        etd: '2010-01-01',
        port_type_id: 1,
        active: true
      }
      FinishedGoodsApp::VoyagePort.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:create)
      assert res.success, 'Should always be able to create a voyage_port'
    end

    def test_edit
      FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:edit, 1)
      assert res.success, 'Should be able to edit a voyage_port'
    end

    def test_delete
      FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:delete, 1)
      assert res.success, 'Should be able to delete a voyage_port'
    end
  end
end
