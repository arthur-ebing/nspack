# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module QcFactory
    def create_qc_measurement_type(opts = {})
      id = get_available_factory_record(:qc_measurement_types, opts)
      return id unless id.nil?

      default = {
        qc_measurement_type_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qc_measurement_types].insert(default.merge(opts))
    end

    def create_qc_sample_type(opts = {})
      id = get_available_factory_record(:qc_sample_types, opts)
      return id unless id.nil?

      default = {
        qc_sample_type_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qc_sample_types].insert(default.merge(opts))
    end

    def create_qc_test_type(opts = {})
      id = get_available_factory_record(:qc_test_types, opts)
      return id unless id.nil?

      default = {
        qc_test_type_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qc_test_types].insert(default.merge(opts))
    end

    def create_fruit_defect_type(opts = {})
      id = get_available_factory_record(:fruit_defect_types, opts)
      return id unless id.nil?

      default = {
        fruit_defect_type_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:fruit_defect_types].insert(default.merge(opts))
    end

    def create_fruit_defect(opts = {})
      id = get_available_factory_record(:fruit_defects, opts)
      return id unless id.nil?

      # rmt_class_id = create_rmt_class
      opts[:rmt_class_id] ||= create_rmt_class
      # fruit_defect_type_id = create_fruit_defect_type
      opts[:fruit_defect_type_id] ||= create_fruit_defect_type

      default = {
        # rmt_class_id: rmt_class_id,
        # fruit_defect_type_id: fruit_defect_type_id,
        fruit_defect_code: Faker::Lorem.unique.word,
        short_description: Faker::Lorem.word,
        description: Faker::Lorem.word,
        internal: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:fruit_defects].insert(default.merge(opts))
    end
  end
end
