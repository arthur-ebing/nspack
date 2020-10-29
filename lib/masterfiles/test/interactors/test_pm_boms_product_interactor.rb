# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmBomsProductInteractor < MiniTestWithHooks
    include PackagingFactory
    include GeneralFactory
    include FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::BomsRepo)
    end

    def test_pm_boms_product
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_boms_product).returns(fake_pm_boms_product)
      entity = interactor.send(:pm_boms_product, 1)
      assert entity.is_a?(PmBomsProduct)
    end

    def test_create_pm_boms_product
      attrs = fake_pm_boms_product.to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_boms_product(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmBomsProduct, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pm_boms_product_fail
      attrs = fake_pm_boms_product(uom_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_boms_product(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:uom_id]
    end

    def test_update_pm_boms_product
      id = create_pm_boms_product
      attrs = interactor.send(:repo).find_pm_boms_product(id)
      attrs = attrs.to_h
      value = attrs[:quantity]
      attrs[:quantity] = 1.0
      res = interactor.update_pm_boms_product(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmBomsProduct, res.instance)
      assert_equal 1.0, res.instance.quantity
      refute_equal value, res.instance.id
    end

    def test_update_pm_boms_product_fail
      id = create_pm_boms_product
      attrs = interactor.send(:repo).find_pm_boms_product(id)
      attrs = attrs.to_h
      attrs.delete(:uom_id)
      value = attrs[:quantity]
      attrs[:quantity] = 1.0
      res = interactor.update_pm_boms_product(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:uom_id]
      after = interactor.send(:repo).find_pm_boms_product(id)
      after = after.to_h
      refute_equal 1.0, after[:quantity]
      assert_equal value, after[:quantity]
    end

    def test_delete_pm_boms_product
      id = create_pm_boms_product
      assert_count_changed(:pm_boms_products, -1) do
        res = interactor.delete_pm_boms_product(id)
        assert res.success, res.message
      end
    end

    private

    def pm_boms_product_attrs
      pm_product_id = create_pm_product
      pm_bom_id = create_pm_bom
      uom_id = create_uom

      {
        id: 1,
        pm_product_id: pm_product_id,
        pm_bom_id: pm_bom_id,
        uom_id: uom_id,
        quantity: 1.0,
        product_code: 'ABC',
        bom_code: 'ABC',
        uom_code: 'ABC',
        active: true
      }
    end

    def fake_pm_boms_product(overrides = {})
      PmBomsProduct.new(pm_boms_product_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PmBomsProductInteractor.new(current_user, {}, {}, {})
    end
  end
end
