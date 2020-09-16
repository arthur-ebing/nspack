# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestStandardProductWeightInteractor < MiniTestWithHooks
    include StandardProductWeightFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FruitSizeRepo)
    end

    def test_standard_product_weight
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_standard_product_weight_flat).returns(fake_standard_product_weight)
      entity = interactor.send(:standard_product_weight, 1)
      assert entity.is_a?(StandardProductWeight)
    end

    def test_create_standard_product_weight
      attrs = fake_standard_product_weight.to_h.reject { |k, _| k == :id }
      res = interactor.create_standard_product_weight(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(StandardProductWeightFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_standard_product_weight_fail
      attrs = fake_standard_product_weight(id: nil).to_h.reject { |k, _| k == :nett_weight }
      res = interactor.create_standard_product_weight(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:nett_weight]
    end

    def test_update_standard_product_weight
      id = create_standard_product_weight
      attrs = interactor.send(:repo).find_hash(:standard_product_weights, id).reject { |k, _| k == :nett_weight }
      value = attrs[:nett_weight]
      attrs[:nett_weight] = 1.234
      res = interactor.update_standard_product_weight(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(StandardProductWeightFlat, res.instance)
      assert_equal 1.234, res.instance.nett_weight
      refute_equal value, res.instance.nett_weight
    end

    def test_update_standard_product_weight_fail
      id = create_standard_product_weight
      attrs = interactor.send(:repo).find_hash(:standard_product_weights, id).reject { |k, _| %i[id nett_weight].include?(k) }
      res = interactor.update_standard_product_weight(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:nett_weight]
    end

    def test_delete_standard_product_weight
      id = create_standard_product_weight
      assert_count_changed(:standard_product_weights, -1) do
        res = interactor.delete_standard_product_weight(id)
        assert res.success, res.message
      end
    end

    private

    def standard_product_weight_attrs
      commodity_id = create_commodity
      standard_pack_code_id = create_standard_pack_code

      {
        id: 1,
        commodity_id: commodity_id,
        standard_pack_id: standard_pack_code_id,
        gross_weight: 1.0,
        nett_weight: 1.0,
        active: true,
        standard_carton_nett_weight: 1.0,
        ratio_to_standard_carton: 1.0,
        is_standard_carton: false
      }
    end

    def fake_standard_product_weight(overrides = {})
      StandardProductWeight.new(standard_product_weight_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= StandardProductWeightInteractor.new(current_user, {}, {}, {})
    end
  end
end
