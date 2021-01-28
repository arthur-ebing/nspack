# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestPackingSpecificationItemInteractor < MiniTestWithHooks
    include PackingSpecificationFactory
    include ProductSetupFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::GeneralFactory
    include RawMaterialsApp::RmtBinFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(ProductionApp::PackingSpecificationRepo)
    end

    def test_packing_specification_item
      ProductionApp::PackingSpecificationRepo.any_instance.stubs(:find_packing_specification_item).returns(fake_packing_specification_item)
      entity = interactor.send(:packing_specification_item, 1)
      assert entity.is_a?(PackingSpecificationItem)
    end

    def test_create_packing_specification_item
      attrs = fake_packing_specification_item.to_h.reject { |k, _| k == :id }
      res = interactor.create_packing_specification_item(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PackingSpecificationItem, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_packing_specification_item_fail
      attrs = fake_packing_specification_item(packing_specification_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_packing_specification_item(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:packing_specification_id]
    end

    def test_update_packing_specification_item
      id = create_packing_specification_item
      attrs = interactor.send(:repo).find_hash(:packing_specification_items, id).reject { |k, _| k == :id }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_packing_specification_item(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PackingSpecificationItem, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_packing_specification_item_fail
      id = create_packing_specification_item
      attrs = interactor.send(:repo).find_hash(:packing_specification_items, id).reject { |k, _| %i[id description].include?(k) }
      res = interactor.update_packing_specification_item(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
    end

    def test_delete_packing_specification_item
      id = create_packing_specification_item
      assert_count_changed(:packing_specification_items, -1) do
        res = interactor.delete_packing_specification_item(id)
        assert res.success, res.message
      end
    end

    private

    def packing_specification_item_attrs
      packing_specification_id = create_packing_specification
      product_setup_template_id = BaseRepo.new.get(:packing_specifications, packing_specification_id, :product_setup_template_id)
      pm_bom_id = create_pm_bom
      pm_mark_id = create_pm_mark
      mark_id = BaseRepo.new.get(:pm_marks, pm_mark_id, :mark_id)
      product_setup_id = create_product_setup
      std_fruit_size_count_id = BaseRepo.new.get(:product_setups, product_setup_id, :std_fruit_size_count_id)
      tu_labour_product_id = create_pm_product
      ru_labour_product_id = create_pm_product

      {
        id: 1,
        packing_specification_id: packing_specification_id,
        product_setup_template_id: product_setup_template_id,
        packing_specification: 'ABC',
        description: Faker::Lorem.unique.word,
        pm_bom_id: pm_bom_id,
        pm_bom: 'ABC',
        pm_mark_id: pm_mark_id,
        mark_id: mark_id,
        pm_mark: 'ABC',
        product_setup_id: product_setup_id,
        std_fruit_size_count_id: std_fruit_size_count_id,
        product_setup: 'ABC',
        tu_labour_product_id: tu_labour_product_id,
        tu_labour_product: 'ABC',
        ru_labour_product_id: ru_labour_product_id,
        ru_labour_product: 'ABC',
        ri_labour_product_id: ru_labour_product_id,
        ri_labour_product: 'ABC',
        fruit_sticker_ids: [1, 2, 3],
        fruit_stickers: %w[A B C],
        fruit_sticker_1: 'ABC',
        fruit_sticker_2: 'ABC',
        tu_sticker_ids: [1, 2, 3],
        tu_stickers: %w[A B C],
        tu_sticker_1: 'ABC',
        tu_sticker_2: 'ABC',
        ru_sticker_ids: [1, 2, 3],
        ru_stickers: %w[A B C],
        ru_sticker_1: 'ABC',
        ru_sticker_2: 'ABC',
        active: true
      }
    end

    def fake_packing_specification_item(overrides = {})
      PackingSpecificationItem.new(packing_specification_item_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PackingSpecificationItemInteractor.new(current_user, {}, {}, {})
    end
  end
end
