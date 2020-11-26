# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmBomInteractor < MiniTestWithHooks
    include PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::BomsRepo)
    end

    def test_pm_bom
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_bom).returns(fake_pm_bom)
      entity = interactor.send(:pm_bom, 1)
      assert entity.is_a?(PmBom)
    end

    def test_create_pm_bom
      attrs = fake_pm_bom.to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_bom(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmBom, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pm_bom_fail
      attrs = fake_pm_bom(bom_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_bom(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:bom_code]
    end

    # def test_update_pm_bom
    #   id = create_pm_bom
    #   attrs = interactor.send(:repo).find_hash(:pm_boms, id).reject { |k, _| k == :id }
    #   value = attrs[:description]
    #   attrs[:description] = 'a_change'
    #   res = interactor.update_pm_bom(id, attrs)
    #   assert res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_instance_of(PmBom, res.instance)
    #   assert_equal 'a_change', res.instance.description
    #   refute_equal value, res.instance.description
    # end

    # def test_update_pm_bom_fail
    #   id = create_pm_bom
    #   attrs = interactor.send(:repo).find_hash(:pm_boms, id)
    #   attrs = attrs.to_h
    #   attrs.delete(:bom_code)
    #   value = attrs[:erp_bom_code]
    #   attrs[:erp_bom_code] = 'a_change'
    #   res = interactor.update_pm_bom(id, attrs)
    #   refute res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_equal ['is missing'], res.errors[:bom_code]
    #   after = interactor.send(:repo).find_hash(:pm_boms, id)
    #   after = after.to_h
    #   refute_equal 'a_change', after[:erp_bom_code]
    #   assert_equal value, after[:erp_bom_code]
    # end

    def test_delete_pm_bom
      id = create_pm_bom
      assert_count_changed(:pm_boms, -1) do
        res = interactor.delete_pm_bom(id)
        assert res.success, res.message
      end
    end

    private

    def pm_bom_attrs
      {
        id: 1,
        bom_code: Faker::Lorem.unique.word,
        erp_bom_code: 'ABC',
        description: 'ABC',
        active: true,
        system_code: 'ABC',
        gross_weight: 1.0,
        nett_weight: 1.0
      }
    end

    def fake_pm_bom(overrides = {})
      PmBom.new(pm_bom_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PmBomInteractor.new(current_user, {}, {}, {})
    end
  end
end
