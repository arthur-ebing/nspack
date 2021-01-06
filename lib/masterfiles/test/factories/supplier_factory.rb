# frozen_string_literal: true

module MasterfilesApp
  module SupplierFactory
    def create_supplier_group(opts = {})
      default = {
        supplier_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:supplier_groups].insert(default.merge(opts))
    end

    def create_supplier(opts = {})
      party_role_id = create_party_role('O', AppConst::ROLE_SUPPLIER)
      supplier_group_ids = [create_supplier_group, create_supplier_group, create_supplier_group]
      farm_ids = [create_farm, create_farm, create_farm]

      default = {
        supplier_party_role_id: party_role_id,
        supplier_group_ids: BaseRepo.new.array_for_db_col(supplier_group_ids),
        farm_ids: BaseRepo.new.array_for_db_col(farm_ids),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:suppliers].insert(default.merge(opts))
    end
  end
end
