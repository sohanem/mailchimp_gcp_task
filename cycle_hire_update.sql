DECLARE fields STRING;
DECLARE updates STRING;

EXECUTE IMMEDIATE (
     "SELECT STRING_AGG(column_name) FROM london_bicycles.INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'cycle_hire'"
  ) INTO fields;

EXECUTE IMMEDIATE (
    """WITH t AS (SELECT column_name FROM london_bicycles.INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'cycle_hire')
       SELECT STRING_AGG("t."||column_name ||" = "|| "s."||column_name) from t join t as s using(column_name)"""
  ) INTO updates;

EXECUTE IMMEDIATE """
  MERGE london_bicycles.cycle_hire T
  USING london_bicycles.cycle_hire_update S
    ON T.rental_id = S.rental_id
  WHEN MATCHED THEN 
    UPDATE SET """||updates||"""
  WHEN NOT MATCHED THEN
    INSERT ("""||fields||""") VALUES ("""||fields||""")"""
