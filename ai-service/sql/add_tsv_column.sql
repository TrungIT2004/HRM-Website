CREATE OR REPLACE FUNCTION document_chunks_tsv() RETURNS trigger AS $$
BEGIN
  NEW.tsv := to_tsvector('simple', unaccent(coalesce(NEW.content,'') || ' ' || coalesce(NEW.breadcrumb,'')));
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_chunks_tsv ON document_chunks;

CREATE TRIGGER trg_chunks_tsv
  BEFORE INSERT OR UPDATE OF content, breadcrumb ON document_chunks
  FOR EACH ROW EXECUTE FUNCTION document_chunks_tsv();
