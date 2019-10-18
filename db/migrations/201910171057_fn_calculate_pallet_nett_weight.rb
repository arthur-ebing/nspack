Sequel.migration do
  up do
    # Function to calculate the nett_weight for a pallet.
    # Provide a pallet_id and pallet gross_weight.

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_calculate_pallet_nett_weight(in_id integer, plt_gross_weight decimal)
        RETURNS decimal AS
      $BODY$
        DECLARE
          plt_std_pack_material_mass DECIMAL;
          plt_base_material_mass DECIMAL;
        BEGIN
          EXECUTE 'SELECT COALESCE(SUM(standard_pack_codes.material_mass), 0)
                   FROM pallets
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
                   WHERE pallets.id = $1'
          INTO plt_std_pack_material_mass
          USING in_id;

          EXECUTE 'SELECT COALESCE(pallet_bases.material_mass, 0)
                   FROM pallets
                   LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
                   LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
                   WHERE pallets.id = $1'
          INTO plt_base_material_mass
          USING in_id;

          RETURN plt_gross_weight - (plt_std_pack_material_mass + plt_base_material_mass);
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_calculate_pallet_nett_weight(integer, decimal)
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP FUNCTION public.fn_calculate_pallet_nett_weight(integer, decimal);
    SQL
  end
end
