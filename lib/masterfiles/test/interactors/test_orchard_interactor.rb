# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestOrchardInteractor < MiniTestWithHooks
    include FarmsFactory
    include PartyFactory
    include CommodityFactory
    include CultivarFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FarmRepo)
    end

    def test_orchard
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_orchard).returns(fake_orchard)
      entity = interactor.send(:orchard, 1)
      assert entity.is_a?(Orchard)
    end

    def test_create_orchard
      attrs = fake_orchard.to_h.reject { |k, _| k == :id }
      res = interactor.create_orchard(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Orchard, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_orchard_fail
      attrs = fake_orchard(orchard_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_orchard(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:orchard_code]
    end

    def test_update_orchard
      id = create_orchard
      attrs = interactor.send(:repo).find_orchard(id)
      attrs = attrs.to_h
      value = attrs[:orchard_code]
      attrs[:orchard_code] = 'a_change'
      res = interactor.update_orchard(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Orchard, res.instance)
      assert_equal 'a_change', res.instance.orchard_code
      refute_equal value, res.instance.orchard_code
    end

    def test_update_orchard_fail
      id = create_orchard
      attrs = interactor.send(:repo).find_orchard(id)
      attrs = attrs.to_h
      attrs.delete(:orchard_code)
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_orchard(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:orchard_code]
      after = interactor.send(:repo).find_orchard(id)
      after = after.to_h
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_orchard
      id = create_orchard
      assert_count_changed(:orchards, -1) do
        res = interactor.delete_orchard(id)
        assert res.success, res.message
      end
    end

    private

    def orchard_attrs
      farm_id = create_farm
      puc_id = create_puc
      cultivar_id = create_cultivar
      farm_section_id = create_farm_section

      {
        id: 1,
        farm_id: farm_id,
        puc_id: puc_id,
        farm_manager_party_role_id: farm_section_id,
        farm_section_name: 'ABC',
        orchard_code: Faker::Lorem.unique.word,
        description: 'ABC',
        cultivar_ids: [cultivar_id],
        puc_code: 'ABC',
        cultivar_names: 'ABC',
        active: true
      }
    end

    def fake_orchard(overrides = {})
      Orchard.new(orchard_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= OrchardInteractor.new(current_user, {}, {}, {})
    end
  end
end
