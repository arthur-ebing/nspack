# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMrlRequirementPermission < Minitest::Test
    include Crossbeams::Responses
    include MrlRequirementFactory
    include PartyFactory
    include CalendarFactory
    include TargetMarketFactory
    include FruitFactory
    include CommodityFactory
    include CultivarFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        season_id: 1,
        qa_standard_id: 1,
        packed_tm_group_id: 1,
        target_market_id: 1,
        target_customer_id: 1,
        cultivar_group_id: 1,
        cultivar_id: 1,
        max_num_chemicals_allowed: 1,
        require_orchard_level_results: false,
        no_results_equal_failure: false,
        active: true
      }
      MasterfilesApp::MrlRequirement.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:create)
      assert res.success, 'Should always be able to create a mrl_requirement'
    end

    def test_edit
      MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:edit, 1)
      assert res.success, 'Should be able to edit a mrl_requirement'

      # MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed mrl_requirement'
    end

    def test_delete
      MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:delete, 1)
      assert res.success, 'Should be able to delete a mrl_requirement'

      # MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed mrl_requirement'
    end

    # def test_complete
    #   MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a mrl_requirement'

    #   MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed mrl_requirement'
    # end

    # def test_approve
    #   MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed mrl_requirement'

    #   MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed mrl_requirement'

    #   MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved mrl_requirement'
    # end

    # def test_reopen
    #   MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a mrl_requirement that has not been approved'

    #   MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::MrlRequirement.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved mrl_requirement'
    # end
  end
end
