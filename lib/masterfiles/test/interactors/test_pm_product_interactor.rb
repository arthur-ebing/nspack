# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmProductInteractor < MiniTestWithHooks
    include PackagingFactory
    include FruitFactory
    include CommodityFactory
    include GeneralFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::BomRepo)
    end

    def test_pm_product
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_product).returns(fake_pm_product)
      entity = interactor.send(:pm_product, 1)
      assert entity.is_a?(PmProduct)
    end

    def test_create_pm_product
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_type).returns(fake_pm_type)
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_subtype).returns(fake_pm_subtype)
      attrs = fake_pm_product.to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_product(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmProduct, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pm_product_fail
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_type).returns(fake_pm_type)
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_subtype).returns(fake_pm_subtype)
      attrs = fake_pm_product(pm_subtype_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_product(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:pm_subtype_id]
    end

    def test_update_pm_product
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_type).returns(fake_pm_type)
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_subtype).returns(fake_pm_subtype)
      id = create_pm_product
      attrs = interactor.send(:repo).find_pm_product(id)
      attrs = attrs.to_h
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pm_product(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmProduct, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_pm_product_fail
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_type).returns(fake_pm_type)
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_subtype).returns(fake_pm_subtype)
      id = create_pm_product
      attrs = interactor.send(:repo).find_pm_product(id)
      attrs = attrs.to_h
      attrs.delete(:pm_subtype_id)
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pm_product(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:pm_subtype_id]
      after = interactor.send(:repo).find_pm_product(id)
      after = after.to_h
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_pm_product
      id = create_pm_product
      assert_count_changed(:pm_products, -1) do
        res = interactor.delete_pm_product(id)
        assert res.success, res.message
      end
    end

    private

    def pm_product_attrs
      pm_subtype_id = create_pm_subtype
      basic_pack_id = create_basic_pack
      std_fruit_size_count_id = create_std_fruit_size_count
      {
        id: 1,
        pm_subtype_id: pm_subtype_id,
        std_fruit_size_count_id: std_fruit_size_count_id,
        erp_code: Faker::Lorem.unique.word,
        product_code: 'ABC',
        description: 'ABC',
        active: true,
        pm_subtype_code: 'ABC',
        material_mass: 1.0,
        basic_pack_id: basic_pack_id,
        height_mm: 1,
        basic_pack_code: 'ABC',
        pm_type_code: 'ABC',
        gross_weight_per_unit: nil,
        items_per_unit: 1,
        items_per_unit_client_description: 'ABC',
        composition_level: 1,
        composition_level_description: 'ABC'
      }
    end

    def fake_pm_product(overrides = {})
      PmProduct.new(pm_product_attrs.merge(overrides))
    end

    def pm_type_attrs
      pm_composition_level_id = create_pm_composition_level

      {
        id: 1,
        pm_composition_level_id: pm_composition_level_id,
        pm_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        composition_level: 'ABC',
        composition_level_description: 'ABC',
        short_code: 'ABC'
      }
    end

    def fake_pm_type(overrides = {})
      PmType.new(pm_type_attrs.merge(overrides))
    end

    def pm_subtype_attrs
      pm_type_id = create_pm_type

      {
        id: 1,
        pm_type_id: pm_type_id,
        subtype_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        pm_type_code: 'ABC',
        short_code: 'ABC',
        composition_level: 1,
        composition_level_description: 'ABC',
        minimum_composition_level: true,
        fruit_composition_level: false
      }
    end

    def fake_pm_subtype(overrides = {})
      PmSubtype.new(pm_subtype_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PmProductInteractor.new(current_user, {}, {}, {})
    end
  end
end
