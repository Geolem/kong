return {
  postgres = {
    up = [[

      UPDATE consumers SET created_at = DATE_TRUNC('seconds', created_at);
      UPDATE plugins   SET created_at = DATE_TRUNC('seconds', created_at);
      UPDATE upstreams SET created_at = DATE_TRUNC('seconds', created_at);
      UPDATE targets   SET created_at = DATE_TRUNC('milliseconds', created_at);

      DO $$
      BEGIN
        ALTER TABLE IF EXISTS ONLY "plugins" ADD "protocols" TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS "plugins_protocols_idx" ON "plugins" ("protocols");
    ]],
  },

  cassandra = {
    up = [[

      ALTER TABLE plugins ADD protocols set<text>;
      CREATE INDEX IF NOT EXISTS ON plugins(protocols);

    ]],
  },
}
