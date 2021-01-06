# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestBinLoadProductInteractor < MiniTestWithHooks
    include BinLoadFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::RmtContainerMaterialTypeFactory
    include RawMaterialsApp::RmtBinFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::BinLoadRepo)
    end

    def test_bin_load_product
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_product_flat).returns(fake_bin_load_product)
      entity = interactor.send(:bin_load_product, 1)
      assert entity.is_a?(BinLoadProduct)
    end

    def test_create_bin_load_product
      attrs = fake_bin_load_product.to_h.reject { |k, _| k == :id }
      res = interactor.create_bin_load_product(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BinLoadProductFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_bin_load_product_fail
      attrs = fake_bin_load_product(id: nil).to_h.reject { |k, _| k == :bin_load_purpose_id }
      res = interactor.create_bin_load_product(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:id]
    end

    def test_update_bin_load_product
      id = create_bin_load_product
      attrs = interactor.send(:repo).find_hash(:bin_load_products, id).reject { |k, _| k == :id }
      value = attrs[:id]
      cultivar_id = create_cultivar
      attrs[:cultivar_id] = cultivar_id
      res = interactor.update_bin_load_product(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BinLoadProductFlat, res.instance)
      assert_equal cultivar_id, res.instance.cultivar_id
      refute_equal value, res.instance.id
    end

    def test_update_bin_load_product_fail
      id = create_bin_load_product
      attrs = interactor.send(:repo).find_hash(:bin_load_products, id).reject { |k, _| %i[id qty_bins].include?(k) }
      res = interactor.update_bin_load_product(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:qty_bins]
    end

    def test_delete_bin_load_product
      id = create_bin_load_product
      assert_count_changed(:bin_load_products, -1) do
        res = interactor.delete_bin_load_product(id)
        assert res.success, res.message
      end
    end

    private

    def bin_load_product_attrs
      bin_load_id = create_bin_load
      cultivar_id = create_cultivar
      cultivar_group_id = create_cultivar_group
      rmt_container_material_type_id = create_rmt_container_material_type
      party_role_id = create_party_role('P', AppConst::ROLE_RMT_BIN_OWNER)
      farm_id = create_farm
      puc_id = create_puc
      orchard_id = create_orchard

      {
        id: 1,
        bin_load_id: bin_load_id,
        qty_bins: 1,
        cultivar_id: cultivar_id,
        cultivar_group_id: cultivar_group_id,
        rmt_container_material_type_id: rmt_container_material_type_id,
        rmt_material_owner_party_role_id: party_role_id,
        farm_id: farm_id,
        puc_id: puc_id,
        orchard_id: orchard_id,
        rmt_class_id: nil,
        active: true
      }
    end

    def fake_bin_load_product(overrides = {})
      BinLoadProduct.new(bin_load_product_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= BinLoadProductInteractor.new(current_user, {}, {}, {})
    end
  end
end
