# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestVoyagePortPermission < Minitest::Test
    include Crossbeams::Responses
    include VoyagePortFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        voyage_id: 1,
        port_id: 1,
        trans_shipment_vessel_id: 1,
        ata: '2010-01-01 12:00',
        atd: '2010-01-01 12:00',
        eta: '2010-01-01 12:00',
        etd: '2010-01-01 12:00',
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

      # FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed voyage_port'
    end

    def test_delete
      FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:delete, 1)
      assert res.success, 'Should be able to delete a voyage_port'

      # FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed voyage_port'
    end

    # def test_complete
    #   FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a voyage_port'

    #   FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity(completed: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed voyage_port'
    # end

    # def test_approve
    #   FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity(completed: true, approved: false))
    #   res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed voyage_port'

    #   FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed voyage_port'

    #   FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved voyage_port'
    # end

    # def test_reopen
    #   FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a voyage_port that has not been approved'

    #   FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::VoyagePort.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved voyage_port'
    # end
  end
end
