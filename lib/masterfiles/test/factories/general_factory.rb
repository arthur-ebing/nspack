# frozen_string_literal: true

module MasterfilesApp
  module GeneralFactory
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
      DB[:uom_types].insert(default.merge(opts))
    end
  end
end
