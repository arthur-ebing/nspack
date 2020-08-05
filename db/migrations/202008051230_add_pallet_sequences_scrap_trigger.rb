Sequel.migration do
  up do
    p 'TEMP: Hold this change back'
    # run <<~SQL
    #   CREATE OR REPLACE FUNCTION public.fn_scrap_pallet_sequences()
    #   RETURNS trigger AS $BODY$
    #
    #   DECLARE
    #     seq_carton_quantity INTEGER;
    #     plt_sequences_count INTEGER;
    #   BEGIN
    #     EXECUTE 'SELECT carton_quantity FROM pallet_sequences WHERE id = $1'
    #     INTO seq_carton_quantity
    #     USING NEW.id;
    #
    #     EXECUTE 'SELECT count(id) FROM pallet_sequences WHERE pallet_id = $1'
    #     INTO plt_sequences_count
    #     USING NEW.pallet_id;
    #
    #     IF (TG_OP = 'UPDATE') THEN 
    #        IF (seq_carton_quantity::integer < 1) THEN
    #            EXECUTE 'UPDATE pallet_sequences SET removed_from_pallet = true, removed_from_pallet_at = $2, pallet_id = null, 
    #                     removed_from_pallet_id = pallet_id, exit_ref = $3
    #                     WHERE id = $1'
    #            USING NEW.id, current_timestamp, 'SEQUENCE REMOVED BY CARTON TRANSFER';
    #        END IF;
    #
    #        IF (plt_sequences_count::integer <= 1 AND seq_carton_quantity::integer < 1) THEN
    #            EXECUTE 'UPDATE pallets SET scrapped = true, scrapped_at = $2, exit_ref = $3
    #                     WHERE id = $1'
    #            USING NEW.pallet_id, current_timestamp, 'SCRAPPED';
    #        END IF;
    #     END IF;
    #
    #     RETURN NEW;
    #   END
    #
    #   $BODY$
    #     LANGUAGE plpgsql VOLATILE
    #     COST 100;
    #   ALTER FUNCTION public.fn_scrap_pallet_sequences()
    #     OWNER TO postgres;
    #
    #   CREATE TRIGGER scrap_pallet_sequences
    #     AFTER UPDATE OF carton_quantity
    #     ON public.pallet_sequences
    #     FOR EACH ROW
    #     EXECUTE PROCEDURE fn_scrap_pallet_sequences();
    # SQL
  end

  down do
    p 'TEMP: Hold this change back'
    # run <<~SQL
    #   DROP TRIGGER scrap_pallet_sequences ON public.pallet_sequences;
    #   DROP FUNCTION public.fn_scrap_pallet_sequences();
    # SQL
  end
end
