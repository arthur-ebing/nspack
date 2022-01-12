Sequel.migration do
  up do
    # Drop logging for gtins table.
    drop_trigger(:gtins, :audit_trigger_row)
    drop_trigger(:gtins, :audit_trigger_stm)
  end

  down do
    # Log changes to gtins table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('gtins', true, true, '{updated_at}'::text[]);"
  end
end
