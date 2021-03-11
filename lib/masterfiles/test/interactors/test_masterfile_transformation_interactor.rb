# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMasterfileTransformationInteractor < MiniTestWithHooks
    include GeneralFactory
    include FarmFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::GeneralRepo)
    end

    def test_masterfile_transformation
      MasterfilesApp::GeneralRepo.any_instance.stubs(:find_masterfile_transformation).returns(fake_masterfile_transformation)
      entity = interactor.send(:masterfile_transformation, 1)
      assert entity.is_a?(MasterfileTransformation)
    end

    def test_create_masterfile_transformation
      attrs = fake_masterfile_transformation.to_h.reject { |k, _| k == :id }
      res = interactor.create_masterfile_transformation(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MasterfileTransformation, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_masterfile_transformation_fail
      attrs = fake_masterfile_transformation(masterfile_table: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_masterfile_transformation(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:masterfile_table]
    end

    def test_update_masterfile_transformation
      id = create_masterfile_transformation
      attrs = interactor.send(:repo).find_hash(:masterfile_transformations, id).reject { |k, _| k == :id }
      value = attrs[:external_code]
      attrs[:external_code] = 'a_change'
      res = interactor.update_masterfile_transformation(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MasterfileTransformation, res.instance)
      assert_equal 'a_change', res.instance.external_code
      refute_equal value, res.instance.masterfile_table
    end

    def test_update_masterfile_transformation_fail
      id = create_masterfile_transformation
      attrs = interactor.send(:repo).find_hash(:masterfile_transformations, id).reject { |k, _| %i[id masterfile_table].include?(k) }
      res = interactor.update_masterfile_transformation(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:masterfile_table]
    end

    def test_delete_masterfile_transformation
      id = create_masterfile_transformation
      assert_count_changed(:masterfile_transformations, -1) do
        res = interactor.delete_masterfile_transformation(id)
        assert res.success, res.message
      end
    end

    private

    def masterfile_transformation_attrs
      {
        id: 1,
        masterfile_table: 'pucs',
        masterfile_column: 'puc_code',
        masterfile_code: 'ABC',
        transformation: 'ABC',
        external_system: 'ABC',
        external_code: 'ABC',
        masterfile_id: 1,
        created_at: '2012-12-01',
        updated_at: '2012-12-01'
      }
    end

    def fake_masterfile_transformation(overrides = {})
      MasterfileTransformation.new(masterfile_transformation_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= MasterfileTransformationInteractor.new(current_user, {}, {}, {})
    end
  end
end
