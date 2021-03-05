# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestPackingSpecificationInteractor < MiniTestWithHooks
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

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(ProductionApp::PackingSpecificationRepo)
    end

    def test_packing_specification
      ProductionApp::PackingSpecificationRepo.any_instance.stubs(:find_packing_specification).returns(fake_packing_specification)
      entity = interactor.send(:packing_specification, 1)
      assert entity.is_a?(PackingSpecification)
    end

    def test_create_packing_specification
      attrs = fake_packing_specification.to_h.reject { |k, _| k == :id }
      res = interactor.create_packing_specification(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PackingSpecification, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_packing_specification_fail
      attrs = fake_packing_specification(packing_specification_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_packing_specification(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:packing_specification_code]
    end

    def test_update_packing_specification
      id = create_packing_specification
      attrs = interactor.send(:repo).find_hash(:packing_specifications, id).reject { |k, _| k == :id }
      value = attrs[:packing_specification_code]
      attrs[:packing_specification_code] = 'a_change'
      res = interactor.update_packing_specification(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PackingSpecification, res.instance)
      assert_equal 'a_change', res.instance.packing_specification_code
      refute_equal value, res.instance.packing_specification_code
    end

    def test_update_packing_specification_fail
      id = create_packing_specification
      attrs = interactor.send(:repo).find_hash(:packing_specifications, id).reject { |k, _| %i[id packing_specification_code].include?(k) }
      res = interactor.update_packing_specification(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:packing_specification_code]
    end

    def test_delete_packing_specification
      id = create_packing_specification
      assert_count_changed(:packing_specifications, -1) do
        res = interactor.delete_packing_specification(id)
        assert res.success, res.message
      end
    end

    private

    def packing_specification_attrs
      product_setup_template_id = create_product_setup_template

      {
        id: 1,
        product_setup_template_id: product_setup_template_id,
        product_setup_template: 'ABC',
        packing_specification_code: Faker::Lorem.unique.word,
        description: 'ABC',
        cultivar_group_code: 'ABC',
        packhouse: 'ABC',
        line: 'ABC',
        active: true
      }
    end

    def fake_packing_specification(overrides = {})
      PackingSpecification.new(packing_specification_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PackingSpecificationInteractor.new(current_user, {}, {}, {})
    end
  end
end
