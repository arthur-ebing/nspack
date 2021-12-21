# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQcInteractor < MiniTestWithHooks
    include QcFactory
    include RawMaterialsApp::RmtBinFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QcRepo)
    end

    # QC MEASUREMENT TYPES
    # --------------------------------------------------------------------------
    def test_qc_measurement_type
      MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_measurement_type).returns(fake_qc_measurement_type)
      entity = interactor.send(:qc_measurement_type, 1)
      assert entity.is_a?(QcMeasurementType)
    end

    def test_create_qc_measurement_type
      attrs = fake_qc_measurement_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_measurement_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcMeasurementType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_qc_measurement_type_fail
      attrs = fake_qc_measurement_type(qc_measurement_type_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_measurement_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:qc_measurement_type_name]
    end

    def test_update_qc_measurement_type
      id = create_qc_measurement_type
      attrs = interactor.send(:repo).find_hash(:qc_measurement_types, id).reject { |k, _| k == :id }
      value = attrs[:qc_measurement_type_name]
      attrs[:qc_measurement_type_name] = 'a_change'
      res = interactor.update_qc_measurement_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcMeasurementType, res.instance)
      assert_equal 'a_change', res.instance.qc_measurement_type_name
      refute_equal value, res.instance.qc_measurement_type_name
    end

    def test_update_qc_measurement_type_fail
      id = create_qc_measurement_type
      attrs = interactor.send(:repo).find_hash(:qc_measurement_types, id).reject { |k, _| %i[id qc_measurement_type_name].include?(k) }
      res = interactor.update_qc_measurement_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:qc_measurement_type_name]
    end

    def test_delete_qc_measurement_type
      id = create_qc_measurement_type(force_create: true)
      assert_count_changed(:qc_measurement_types, -1) do
        res = interactor.delete_qc_measurement_type(id)
        assert res.success, res.message
      end
    end

    # QC SAMPLE TYPES
    # --------------------------------------------------------------------------
    def test_qc_sample_type
      MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_sample_type).returns(fake_qc_sample_type)
      entity = interactor.send(:qc_sample_type, 1)
      assert entity.is_a?(QcSampleType)
    end

    def test_create_qc_sample_type
      attrs = fake_qc_sample_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_sample_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcSampleType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_qc_sample_type_fail
      attrs = fake_qc_sample_type(qc_sample_type_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_sample_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:qc_sample_type_name]
    end

    def test_update_qc_sample_type
      id = create_qc_sample_type
      attrs = interactor.send(:repo).find_hash(:qc_sample_types, id).reject { |k, _| k == :id }
      value = attrs[:qc_sample_type_name]
      attrs[:qc_sample_type_name] = 'a_change'
      res = interactor.update_qc_sample_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcSampleType, res.instance)
      assert_equal 'a_change', res.instance.qc_sample_type_name
      refute_equal value, res.instance.qc_sample_type_name
    end

    def test_update_qc_sample_type_fail
      id = create_qc_sample_type
      attrs = interactor.send(:repo).find_hash(:qc_sample_types, id).reject { |k, _| %i[id qc_sample_type_name].include?(k) }
      res = interactor.update_qc_sample_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:qc_sample_type_name]
    end

    def test_delete_qc_sample_type
      id = create_qc_sample_type(force_create: true)
      assert_count_changed(:qc_sample_types, -1) do
        res = interactor.delete_qc_sample_type(id)
        assert res.success, res.message
      end
    end

    # QC TEST TYPES
    # --------------------------------------------------------------------------
    def test_qc_test_type
      MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_test_type).returns(fake_qc_test_type)
      entity = interactor.send(:qc_test_type, 1)
      assert entity.is_a?(QcTestType)
    end

    def test_create_qc_test_type
      attrs = fake_qc_test_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_test_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcTestType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_qc_test_type_fail
      attrs = fake_qc_test_type(qc_test_type_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_test_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:qc_test_type_name]
    end

    def test_update_qc_test_type
      id = create_qc_test_type
      attrs = interactor.send(:repo).find_hash(:qc_test_types, id).reject { |k, _| k == :id }
      value = attrs[:qc_test_type_name]
      attrs[:qc_test_type_name] = 'a_change'
      res = interactor.update_qc_test_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcTestType, res.instance)
      assert_equal 'a_change', res.instance.qc_test_type_name
      refute_equal value, res.instance.qc_test_type_name
    end

    def test_update_qc_test_type_fail
      id = create_qc_test_type
      attrs = interactor.send(:repo).find_hash(:qc_test_types, id).reject { |k, _| %i[id qc_test_type_name].include?(k) }
      res = interactor.update_qc_test_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:qc_test_type_name]
    end

    def test_delete_qc_test_type
      id = create_qc_test_type(force_create: true)
      assert_count_changed(:qc_test_types, -1) do
        res = interactor.delete_qc_test_type(id)
        assert res.success, res.message
      end
    end

    # FRUIT DEFECT CATEGORIES
    # --------------------------------------------------------------------------
    def test_fruit_defect_category
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(fake_fruit_defect_category)
      entity = interactor.send(:fruit_defect_category, 1)
      assert entity.is_a?(FruitDefectCategory)
    end

    def test_create_fruit_defect_category
      attrs = fake_fruit_defect_category.to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_defect_category(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitDefectCategory, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_fruit_defect_category_fail
      attrs = fake_fruit_defect_category(defect_category: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_defect_category(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:defect_category]
    end

    def test_update_fruit_defect_category
      id = create_fruit_defect_category
      attrs = interactor.send(:repo).find_hash(:fruit_defect_categories, id).reject { |k, _| k == :id }
      value = attrs[:defect_category]
      attrs[:defect_category] = 'a_change'
      res = interactor.update_fruit_defect_category(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitDefectCategory, res.instance)
      assert_equal 'a_change', res.instance.defect_category
      refute_equal value, res.instance.defect_category
    end

    def test_update_fruit_defect_category_fail
      id = create_fruit_defect_category
      attrs = interactor.send(:repo).find_hash(:fruit_defect_categories, id).reject { |k, _| %i[id defect_category].include?(k) }
      res = interactor.update_fruit_defect_category(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:defect_category]
    end

    def test_delete_fruit_defect_category
      id = create_fruit_defect_category(force_create: true)
      assert_count_changed(:fruit_defect_categories, -1) do
        res = interactor.delete_fruit_defect_category(id)
        assert res.success, res.message
      end
    end

    # FRUIT DEFECT TYPES
    # --------------------------------------------------------------------------
    def test_fruit_defect_type
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(fake_fruit_defect_type)
      entity = interactor.send(:fruit_defect_type, 1)
      assert entity.is_a?(FruitDefectType)
    end

    def test_create_fruit_defect_type
      attrs = fake_fruit_defect_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_defect_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitDefectType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_fruit_defect_type_fail
      attrs = fake_fruit_defect_type(fruit_defect_type_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_defect_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:fruit_defect_type_name]
    end

    def test_update_fruit_defect_type
      id = create_fruit_defect_type
      attrs = interactor.send(:repo).find_hash(:fruit_defect_types, id).reject { |k, _| k == :id }
      value = attrs[:fruit_defect_type_name]
      attrs[:fruit_defect_type_name] = 'a_change'
      res = interactor.update_fruit_defect_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitDefectType, res.instance)
      assert_equal 'a_change', res.instance.fruit_defect_type_name
      refute_equal value, res.instance.fruit_defect_type_name
    end

    def test_update_fruit_defect_type_fail
      id = create_fruit_defect_type
      attrs = interactor.send(:repo).find_hash(:fruit_defect_types, id).reject { |k, _| %i[id fruit_defect_type_name].include?(k) }
      res = interactor.update_fruit_defect_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:fruit_defect_type_name]
    end

    def test_delete_fruit_defect_type
      id = create_fruit_defect_type(force_create: true)
      assert_count_changed(:fruit_defect_types, -1) do
        res = interactor.delete_fruit_defect_type(id)
        assert res.success, res.message
      end
    end

    # FRUIT DEFECTS
    # --------------------------------------------------------------------------
    def test_fruit_defect
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(fake_fruit_defect)
      entity = interactor.send(:fruit_defect, 1)
      assert entity.is_a?(FruitDefect)
    end

    def test_create_fruit_defect
      attrs = fake_fruit_defect.to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_defect(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitDefect, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_fruit_defect_fail
      attrs = fake_fruit_defect(fruit_defect_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_defect(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:fruit_defect_code]
    end

    def test_update_fruit_defect
      id = create_fruit_defect
      attrs = interactor.send(:repo).find_hash(:fruit_defects, id).reject { |k, _| k == :id }
      value = attrs[:fruit_defect_code]
      attrs[:fruit_defect_code] = 'a_change'
      res = interactor.update_fruit_defect(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitDefect, res.instance)
      assert_equal 'a_change', res.instance.fruit_defect_code
      refute_equal value, res.instance.fruit_defect_code
    end

    def test_update_fruit_defect_fail
      id = create_fruit_defect
      attrs = interactor.send(:repo).find_hash(:fruit_defects, id).reject { |k, _| %i[id fruit_defect_code].include?(k) }
      res = interactor.update_fruit_defect(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:fruit_defect_code]
    end

    def test_delete_fruit_defect
      id = create_fruit_defect(force_create: true)
      assert_count_changed(:fruit_defects, -1) do
        res = interactor.delete_fruit_defect(id)
        assert res.success, res.message
      end
    end

    private

    def qc_measurement_type_attrs
      {
        id: 1,
        qc_measurement_type_name: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_qc_measurement_type(overrides = {})
      QcMeasurementType.new(qc_measurement_type_attrs.merge(overrides))
    end

    def qc_sample_type_attrs
      {
        id: 1,
        qc_sample_type_name: Faker::Lorem.unique.word,
        description: 'ABC',
        default_sample_size: 1,
        required_for_first_orchard_delivery: false,
        active: true
      }
    end

    def fake_qc_sample_type(overrides = {})
      QcSampleType.new(qc_sample_type_attrs.merge(overrides))
    end

    def qc_test_type_attrs
      {
        id: 1,
        qc_test_type_name: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_qc_test_type(overrides = {})
      QcTestType.new(qc_test_type_attrs.merge(overrides))
    end

    def fruit_defect_category_attrs
      {
        id: 1,
        defect_category: Faker::Lorem.unique.word,
        reporting_description: 'ABC',
        active: true
      }
    end

    def fake_fruit_defect_category(overrides = {})
      FruitDefectCategory.new(fruit_defect_category_attrs.merge(overrides))
    end

    def fruit_defect_type_attrs
      {
        id: 1,
        fruit_defect_type_name: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_fruit_defect_type(overrides = {})
      FruitDefectType.new(fruit_defect_type_attrs.merge(overrides))
    end

    def fruit_defect_attrs
      fruit_defect_type_id = create_fruit_defect_type

      {
        id: 1,
        fruit_defect_type_id: fruit_defect_type_id,
        fruit_defect_code: Faker::Lorem.unique.word,
        short_description: 'ABC',
        description: 'ABC',
        reporting_description: 'ABC',
        internal: false,
        external: false,
        pre_harvest: false,
        post_harvest: false,
        severity: 'ABC',
        qc_class_2: false,
        qc_class_3: false,
        active: true
      }
    end

    def fake_fruit_defect(overrides = {})
      FruitDefect.new(fruit_defect_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= QcInteractor.new(current_user, {}, {}, {})
    end
  end
end
