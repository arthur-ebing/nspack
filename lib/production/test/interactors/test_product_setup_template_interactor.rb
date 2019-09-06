# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductSetupTemplateInteractor < MiniTestWithHooks
    include ProductSetupFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(ProductionApp::ProductSetupRepo)
    end

    def test_product_setup_template
      ProductionApp::ProductSetupRepo.any_instance.stubs(:find_product_setup_template).returns(fake_product_setup_template)
      entity = interactor.send(:product_setup_template, 1)
      assert entity.is_a?(ProductSetupTemplate)
    end

    def test_create_product_setup_template
      attrs = fake_product_setup_template.to_h.reject { |k, _| k == :id }
      res = interactor.create_product_setup_template(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ProductSetupTemplate, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_product_setup_template_fail
      attrs = fake_product_setup_template(template_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_product_setup_template(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:template_name]
    end

    def test_update_product_setup_template
      id = create_product_setup_template
      attrs = interactor.send(:repo).find_hash(:product_setup_templates, id).reject { |k, _| k == :id }
      value = attrs[:template_name]
      attrs[:template_name] = 'a_change'
      res = interactor.update_product_setup_template(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ProductSetupTemplate, res.instance)
      assert_equal 'a_change', res.instance.template_name
      refute_equal value, res.instance.template_name
    end

    def test_update_product_setup_template_fail
      id = create_product_setup_template
      attrs = interactor.send(:repo).find_hash(:product_setup_templates, id).reject { |k, _| %i[id template_name].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_product_setup_template(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:template_name]
      after = interactor.send(:repo).find_hash(:product_setup_templates, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_product_setup_template
      id = create_product_setup_template
      assert_count_changed(:product_setup_templates, -1) do
        res = interactor.delete_product_setup_template(id)
        assert res.success, res.message
      end
    end

    private

    def product_setup_template_attrs
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar
      # packhouse_resource_id = create_plant_resource
      # production_line_resource_id = create_plant_resource
      season_group_id = create_season_group
      season_id = create_season

      {
        id: 1,
        template_name: Faker::Lorem.unique.word,
        description: 'ABC',
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        packhouse_resource_id: nil,
        production_line_resource_id: nil,
        season_group_id: season_group_id,
        season_id: season_id,
        active: true,
        cultivar_group_code: 'ABC',
        cultivar_name: 'ABC',
        packhouse_resource_code: 'ABC',
        production_line_resource_code: 'ABC',
        season_group_code: 'ABC',
        season_code: 'ABC'
      }
    end

    def fake_product_setup_template(overrides = {})
      ProductSetupTemplate.new(product_setup_template_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ProductSetupTemplateInteractor.new(current_user, {}, {}, {})
    end
  end
end
