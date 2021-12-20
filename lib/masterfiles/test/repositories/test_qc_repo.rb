# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQcRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_qc_measurement_types
      assert_respond_to repo, :for_select_qc_sample_types
      assert_respond_to repo, :for_select_qc_test_types
      assert_respond_to repo, :for_select_fruit_defect_types
      assert_respond_to repo, :for_select_fruit_defects
    end

    def test_crud_calls
      test_crud_calls_for :qc_measurement_types, name: :qc_measurement_type, wrapper: QcMeasurementType
      test_crud_calls_for :qc_sample_types, name: :qc_sample_type, wrapper: QcSampleType
      test_crud_calls_for :qc_test_types, name: :qc_test_type, wrapper: QcTestType
      test_crud_calls_for :fruit_defect_types, name: :fruit_defect_type, wrapper: FruitDefectType
      test_crud_calls_for :fruit_defects, name: :fruit_defect, wrapper: FruitDefect
    end

    private

    def repo
      QcRepo.new
    end
  end
end
