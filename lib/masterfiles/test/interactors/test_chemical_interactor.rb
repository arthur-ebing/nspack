# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestChemicalInteractor < MiniTestWithHooks
    include ChemicalFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::ChemicalRepo)
    end

    def test_chemical
      MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(fake_chemical)
      entity = interactor.send(:chemical, 1)
      assert entity.is_a?(Chemical)
    end

    def test_create_chemical
      attrs = fake_chemical.to_h.reject { |k, _| k == :id }
      res = interactor.create_chemical(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Chemical, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_chemical_fail
      attrs = fake_chemical(chemical_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_chemical(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:chemical_name]
    end

    def test_update_chemical
      id = create_chemical
      attrs = interactor.send(:repo).find_hash(:chemicals, id).reject { |k, _| k == :id }
      value = attrs[:chemical_name]
      attrs[:chemical_name] = 'a_change'
      res = interactor.update_chemical(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Chemical, res.instance)
      assert_equal 'a_change', res.instance.chemical_name
      refute_equal value, res.instance.chemical_name
    end

    def test_update_chemical_fail
      id = create_chemical
      attrs = interactor.send(:repo).find_hash(:chemicals, id).reject { |k, _| %i[id chemical_name].include?(k) }
      res = interactor.update_chemical(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:chemical_name]
    end

    def test_delete_chemical
      id = create_chemical(force_create: true)
      assert_count_changed(:chemicals, -1) do
        res = interactor.delete_chemical(id)
        assert res.success, res.message
      end
    end

    private

    def chemical_attrs
      {
        id: 1,
        chemical_name: Faker::Lorem.unique.word,
        description: 'ABC',
        eu_max_level: 1.0,
        arfd_max_level: 1.0,
        orchard_chemical: false,
        drench_chemical: false,
        packline_chemical: false,
        active: true
      }
    end

    def fake_chemical(overrides = {})
      Chemical.new(chemical_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ChemicalInteractor.new(current_user, {}, {}, {})
    end
  end
end
