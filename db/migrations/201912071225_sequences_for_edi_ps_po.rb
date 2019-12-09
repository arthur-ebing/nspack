Sequel.migration do
  up do
    run <<~SQL
      CREATE SEQUENCE doc_seqs_edi_out_ps;
      CREATE SEQUENCE doc_seqs_edi_out_po;
    SQL
  end

  down do
    run <<~SQL
      DROP SEQUENCE doc_seqs_edi_out_ps;
      DROP SEQUENCE doc_seqs_edi_out_po;
    SQL
  end
end
