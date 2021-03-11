# frozen_string_literal: true

module MasterfilesApp
  module GeneralFactory
    def create_masterfile_transformation(opts = {})
      puc_id = create_puc
      default = {
        masterfile_table: 'pucs',
        masterfile_id: puc_id,
        external_system: Faker::Lorem.word,
        external_code: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:masterfile_transformations].insert(default.merge(opts))
    end

    def create_masterfile_variant(opts = {})
      puc_id = create_puc
      default = {
        masterfile_table: 'pucs',
        masterfile_id: puc_id,
        variant_code: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:masterfile_variants].insert(default.merge(opts))
    end

    def create_uom(opts = {})
      uom_type_id = create_uom_type

      default = {
        uom_type_id: uom_type_id,
        uom_code: Faker::Lorem.unique.word,
        active: true
      }
      DB[:uoms].insert(default.merge(opts))
    end

    def create_uom_type(opts = {})
      default = {
        code: AppConst::UOM_TYPE,
        active: true
      }
      DB[:uom_types].where(default.merge(opts)).get(:id) || DB[:uom_types].insert(default.merge(opts))
    end
  end
end
