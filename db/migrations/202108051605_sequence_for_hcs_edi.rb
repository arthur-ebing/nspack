Sequel.migration do
  up do
    run <<~SQL
      CREATE SEQUENCE doc_seqs_edi_out_hcs;
    SQL
  end

  down do
    run <<~SQL
      DROP SEQUENCE doc_seqs_edi_out_hcs;
    SQL
  end
end

