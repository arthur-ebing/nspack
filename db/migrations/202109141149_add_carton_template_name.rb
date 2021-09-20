Sequel.migration do
  up do
    alter_table(:product_setups) do
      add_foreign_key :carton_label_template_id , :label_templates, key: [:id]
    end
  end

  down do
    alter_table(:product_setups) do
      drop_column :carton_label_template_id
    end
  end
end