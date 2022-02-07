# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQaStandardTypePermission < Minitest::Test
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
        qa_standard_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::QaStandardType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:create)
      assert res.success, 'Should always be able to create a qa_standard_type'
    end

    def test_edit
      MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:edit, 1)
      assert res.success, 'Should be able to edit a qa_standard_type'

      # MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed qa_standard_type'
    end

    def test_delete
      MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:delete, 1)
      assert res.success, 'Should be able to delete a qa_standard_type'

      # MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed qa_standard_type'
    end

    # def test_complete
    #   MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a qa_standard_type'

    #   MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed qa_standard_type'
    # end

    # def test_approve
    #   MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed qa_standard_type'

    #   MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed qa_standard_type'

    #   MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved qa_standard_type'
    # end

    # def test_reopen
    #   MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a qa_standard_type that has not been approved'

    #   MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandardType.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved qa_standard_type'
    # end
  end
end
