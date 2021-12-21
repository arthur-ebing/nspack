# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestQcSamplePermission < Minitest::Test
    include Crossbeams::Responses
    include QcFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        qc_sample_type_id: 1,
        rmt_delivery_id: 1,
        coldroom_location_id: 1,
        production_run_id: 1,
        orchard_id: 1,
        presort_run_lot_number: Faker::Lorem.unique.word,
        ref_number: 'ABC',
        short_description: 'ABC',
        sample_size: 1,
        editing: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        drawn_at: '2010-01-01 12:00',
        rmt_bin_ids: [1, 2, 3]
      }
      QualityApp::QcSample.new(base_attrs.merge(attrs))
    end

    def test_create
      res = QualityApp::TaskPermissionCheck::QcSample.call(:create)
      assert res.success, 'Should always be able to create a qc_sample'
    end

    def test_edit
      QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity)
      res = QualityApp::TaskPermissionCheck::QcSample.call(:edit, 1)
      assert res.success, 'Should be able to edit a qc_sample'

      # QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity(completed: true))
      # res = QualityApp::TaskPermissionCheck::QcSample.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed qc_sample'
    end

    def test_delete
      QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity)
      res = QualityApp::TaskPermissionCheck::QcSample.call(:delete, 1)
      assert res.success, 'Should be able to delete a qc_sample'

      # QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity(completed: true))
      # res = QualityApp::TaskPermissionCheck::QcSample.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed qc_sample'
    end

    # def test_complete
    #   QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity)
    #   res = QualityApp::TaskPermissionCheck::QcSample.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a qc_sample'

    #   QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity(completed: true))
    #   res = QualityApp::TaskPermissionCheck::QcSample.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed qc_sample'
    # end

    # def test_approve
    #   QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity(completed: true, approved: false))
    #   res = QualityApp::TaskPermissionCheck::QcSample.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed qc_sample'

    #   QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity)
    #   res = QualityApp::TaskPermissionCheck::QcSample.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed qc_sample'

    #   QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity(completed: true, approved: true))
    #   res = QualityApp::TaskPermissionCheck::QcSample.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved qc_sample'
    # end

    # def test_reopen
    #   QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity)
    #   res = QualityApp::TaskPermissionCheck::QcSample.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a qc_sample that has not been approved'

    #   QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(entity(completed: true, approved: true))
    #   res = QualityApp::TaskPermissionCheck::QcSample.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved qc_sample'
    # end
  end
end
