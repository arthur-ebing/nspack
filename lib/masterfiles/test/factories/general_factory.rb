# frozen_string_literal: true

module MasterfilesApp
  module GeneralFactory
    def create_masterfile_transformation(opts = {})
      id = get_available_factory_record(:masterfile_transformations, opts)
      return id unless id.nil?

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
      id = get_available_factory_record(:masterfile_variants, opts)
      return id unless id.nil?

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
      id = get_available_factory_record(:uoms, opts)
      return id unless id.nil?

      uom_type_id = create_uom_type
      default = {
        uom_type_id: uom_type_id,
        uom_code: Faker::Lorem.unique.word,
        active: true
      }
      DB[:uoms].insert(default.merge(opts))
    end

    def create_uom_type(opts = {})
      id = get_available_factory_record(:uom_types, opts)
      return id unless id.nil?

      default = {
        code: Faker::Lorem.unique.word,
        active: true
      }
      DB[:uom_types].insert(default.merge(opts))
    end
  end
end
