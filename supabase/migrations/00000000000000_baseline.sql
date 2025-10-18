

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."create_case_with_transaction"("p_user_id" "uuid", "p_jurisdiction" "text", "p_county" "text", "p_case_type" "text", "p_attorney_id" "text", "p_reference_id" "text", "p_status" "text" DEFAULT 'Open'::"text", "p_case_category" "text" DEFAULT '7'::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_case_id UUID;
BEGIN
  -- Insert new case and return the ID
  INSERT INTO public.cases (
    id,
    plaintiff,
    defendant,
    address,
    status
  ) VALUES (
    gen_random_uuid(),
    CONCAT(p_jurisdiction, ' County Court'),
    CONCAT('Case ', p_reference_id, ' - ', p_case_type),
    CONCAT(p_county, ' County, ', UPPER(p_jurisdiction)),
    p_status
  )
  RETURNING id INTO v_case_id;

  RETURN v_case_id;
END;
$$;


ALTER FUNCTION "public"."create_case_with_transaction"("p_user_id" "uuid", "p_jurisdiction" "text", "p_county" "text", "p_case_type" "text", "p_attorney_id" "text", "p_reference_id" "text", "p_status" "text", "p_case_category" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_document_with_validation"("p_case_id" "uuid", "p_envelope_id" "text", "p_filing_id" "text", "p_file_name" "text", "p_doc_type" "text", "p_efile_status" "text", "p_efile_timestamp" timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_document_id UUID;
  v_case_exists BOOLEAN;
BEGIN
  -- Validate that the case exists
  SELECT EXISTS(SELECT 1 FROM public.cases WHERE id = p_case_id) INTO v_case_exists;
  
  IF NOT v_case_exists THEN
    RAISE EXCEPTION 'Case with ID % does not exist', p_case_id;
  END IF;

  -- Check for duplicate envelope_id + filing_id combination
  IF EXISTS(
    SELECT 1 FROM public.documents 
    WHERE envelope_id = p_envelope_id 
    AND filing_id = p_filing_id
    AND envelope_id IS NOT NULL 
    AND filing_id IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Document with envelope_id % and filing_id % already exists', p_envelope_id, p_filing_id;
  END IF;

  -- Insert new document
  INSERT INTO public.documents (
    case_id,
    envelope_id,
    filing_id,
    original_filename,
    type,
    file_url,
    status,
    efile_status,
    efile_timestamp
  ) VALUES (
    p_case_id,
    p_envelope_id,
    p_filing_id,
    p_file_name,
    p_doc_type,
    '', -- file_url not needed for e-filed documents
    'Pending',
    p_efile_status,
    p_efile_timestamp
  )
  RETURNING id INTO v_document_id;

  RETURN v_document_id;
END;
$$;


ALTER FUNCTION "public"."create_document_with_validation"("p_case_id" "uuid", "p_envelope_id" "text", "p_filing_id" "text", "p_file_name" "text", "p_doc_type" "text", "p_efile_status" "text", "p_efile_timestamp" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_schema_version"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  current_version TEXT;
BEGIN
  SELECT version INTO current_version
  FROM public.schema_versions
  WHERE is_success = true
  ORDER BY applied_at DESC
  LIMIT 1;
  
  RETURN COALESCE(current_version, 'none');
END;
$$;


ALTER FUNCTION "public"."get_current_schema_version"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_migration_event"("p_version" "text", "p_level" "text", "p_message" "text", "p_context" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO public.migration_logs (migration_version, log_level, message, context)
  VALUES (p_version, p_level, p_message, p_context)
  RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$;


ALTER FUNCTION "public"."log_migration_event"("p_version" "text", "p_level" "text", "p_message" "text", "p_context" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."log_migration_event"("p_version" "text", "p_level" "text", "p_message" "text", "p_context" "jsonb") IS 'Log events during migration operations';



CREATE OR REPLACE FUNCTION "public"."record_metric"("p_metric_name" "text", "p_metric_value" numeric, "p_metric_unit" "text" DEFAULT NULL::"text", "p_tags" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  metric_id UUID;
BEGIN
  INSERT INTO public.system_health (metric_name, metric_value, metric_unit, tags)
  VALUES (p_metric_name, p_metric_value, p_metric_unit, p_tags)
  RETURNING id INTO metric_id;
  
  RETURN metric_id;
END;
$$;


ALTER FUNCTION "public"."record_metric"("p_metric_name" "text", "p_metric_value" numeric, "p_metric_unit" "text", "p_tags" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."record_metric"("p_metric_name" "text", "p_metric_value" numeric, "p_metric_unit" "text", "p_tags" "jsonb") IS 'Record system performance metrics';



CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_schema_integrity"() RETURNS TABLE("table_name" "text", "issue_type" "text", "description" "text", "severity" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Check for missing foreign key constraints
  RETURN QUERY
  SELECT 
    t.table_name::TEXT,
    'missing_fk'::TEXT as issue_type,
    'Table references another table without foreign key constraint'::TEXT as description,
    'medium'::TEXT as severity
  FROM information_schema.tables t
  WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
    AND NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints tc
      WHERE tc.table_name = t.table_name
        AND tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
    )
    AND t.table_name IN ('case_contacts', 'contact_communications'); -- Tables that should have FKs

  -- Check for tables without RLS
  RETURN QUERY
  SELECT 
    schemaname::TEXT as table_name,
    'missing_rls'::TEXT as issue_type,
    'Table does not have Row Level Security enabled'::TEXT as description,
    'high'::TEXT as severity
  FROM pg_tables
  WHERE schemaname = 'public'
    AND tablename NOT IN ('schema_versions', 'migration_logs', 'system_health')
    AND NOT EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON c.relnamespace = n.oid
      WHERE c.relname = pg_tables.tablename
        AND n.nspname = 'public'
        AND c.relrowsecurity = true
    );

  -- Check for missing indexes on foreign keys
  RETURN QUERY
  SELECT 
    tc.table_name::TEXT,
    'missing_fk_index'::TEXT as issue_type,
    ('Foreign key column ' || kcu.column_name || ' lacks index')::TEXT as description,
    'medium'::TEXT as severity
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND NOT EXISTS (
      SELECT 1 FROM pg_indexes i
      WHERE i.schemaname = 'public'
        AND i.tablename = tc.table_name
        AND position(kcu.column_name in i.indexdef) > 0
    );

END;
$$;


ALTER FUNCTION "public"."validate_schema_integrity"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."validate_schema_integrity"() IS 'Validate database schema for common issues';


SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."case_contacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "case_id" "uuid" NOT NULL,
    "contact_id" "uuid" NOT NULL,
    "relationship_type" "text" NOT NULL,
    "is_primary" boolean DEFAULT false,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "case_contacts_relationship_type_check" CHECK (("relationship_type" = ANY (ARRAY['Plaintiff'::"text", 'Defendant'::"text", 'Attorney'::"text", 'Paralegal'::"text", 'Property Manager'::"text", 'Witness'::"text", 'Expert'::"text", 'Court Reporter'::"text", 'Other'::"text"])))
);


ALTER TABLE "public"."case_contacts" OWNER TO "postgres";


COMMENT ON TABLE "public"."case_contacts" IS 'Junction table linking cases to contacts with relationship types';



COMMENT ON COLUMN "public"."case_contacts"."relationship_type" IS 'Defines the role of the contact in this specific case';



COMMENT ON COLUMN "public"."case_contacts"."is_primary" IS 'Marks the primary contact for this relationship type in the case';



CREATE TABLE IF NOT EXISTS "public"."cases" (
    "id" "uuid" NOT NULL,
    "plaintiff" "text" NOT NULL,
    "defendant" "text" NOT NULL,
    "address" "text",
    "status" "text" DEFAULT 'Intake'::"text" NOT NULL,
    "intakedate" timestamp with time zone DEFAULT "now"() NOT NULL,
    "createdat" timestamp with time zone DEFAULT "now"(),
    "updatedat" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contact_communications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contact_id" "uuid" NOT NULL,
    "case_id" "uuid",
    "communication_type" "text" NOT NULL,
    "subject" "text",
    "content" "text" NOT NULL,
    "direction" "text" NOT NULL,
    "communication_date" timestamp with time zone DEFAULT "now"() NOT NULL,
    "follow_up_required" boolean DEFAULT false,
    "follow_up_date" "date",
    "created_by" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "contact_communications_communication_type_check" CHECK (("communication_type" = ANY (ARRAY['Email'::"text", 'Phone Call'::"text", 'Meeting'::"text", 'Letter'::"text", 'Text Message'::"text", 'Video Call'::"text", 'Other'::"text"]))),
    CONSTRAINT "contact_communications_direction_check" CHECK (("direction" = ANY (ARRAY['Incoming'::"text", 'Outgoing'::"text"])))
);


ALTER TABLE "public"."contact_communications" OWNER TO "postgres";


COMMENT ON TABLE "public"."contact_communications" IS 'Log of all communications with contacts';



COMMENT ON COLUMN "public"."contact_communications"."case_id" IS 'Optional case context for the communication';



COMMENT ON COLUMN "public"."contact_communications"."direction" IS 'Whether communication was incoming (to us) or outgoing (from us)';



CREATE TABLE IF NOT EXISTS "public"."contacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "role" "text" NOT NULL,
    "email" "text" NOT NULL,
    "phone" "text",
    "company" "text",
    "address" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "contacts_email_check" CHECK (("email" ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'::"text")),
    CONSTRAINT "contacts_name_check" CHECK ((("length"("name") >= 1) AND ("length"("name") <= 100))),
    CONSTRAINT "contacts_role_check" CHECK (("role" = ANY (ARRAY['Attorney'::"text", 'Paralegal'::"text", 'PM'::"text", 'Client'::"text", 'Other'::"text"])))
);


ALTER TABLE "public"."contacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "case_id" "uuid",
    "type" "text" NOT NULL,
    "file_url" "text" NOT NULL,
    "status" "text" DEFAULT 'Pending'::"text" NOT NULL,
    "service_date" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "original_filename" "text",
    "envelope_id" "text",
    "filing_id" "text",
    "efile_status" "text",
    "efile_timestamp" timestamp with time zone,
    CONSTRAINT "documents_status_check" CHECK (("status" = ANY (ARRAY['Pending'::"text", 'Served'::"text", 'Failed'::"text"]))),
    CONSTRAINT "documents_type_check" CHECK (("type" = ANY (ARRAY['Complaint'::"text", 'Summons'::"text", 'Affidavit'::"text", 'Motion'::"text", 'Order'::"text", 'Other'::"text"])))
);


ALTER TABLE "public"."documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."hearings" (
    "id" "uuid" NOT NULL,
    "case_id" "uuid",
    "court_name" "text",
    "hearing_date" timestamp with time zone NOT NULL,
    "participants" "text"[] DEFAULT '{}'::"text"[],
    "outcome" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."hearings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."migration_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "migration_version" "text" NOT NULL,
    "log_level" "text" NOT NULL,
    "message" "text" NOT NULL,
    "context" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "migration_logs_log_level_check" CHECK (("log_level" = ANY (ARRAY['INFO'::"text", 'WARN'::"text", 'ERROR'::"text", 'DEBUG'::"text"])))
);


ALTER TABLE "public"."migration_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."migration_logs" IS 'Detailed logs for migration operations and events';



CREATE TABLE IF NOT EXISTS "public"."schema_versions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "version" "text" NOT NULL,
    "description" "text" NOT NULL,
    "migration_file" "text" NOT NULL,
    "applied_at" timestamp with time zone DEFAULT "now"(),
    "applied_by" "text",
    "rollback_sql" "text",
    "checksum" "text",
    "execution_time_ms" integer,
    "is_success" boolean DEFAULT true,
    "error_message" "text",
    CONSTRAINT "version_format" CHECK (("version" ~ '^\d{14}_[a-z0-9_]+$'::"text"))
);


ALTER TABLE "public"."schema_versions" OWNER TO "postgres";


COMMENT ON TABLE "public"."schema_versions" IS 'Tracks all database schema migrations and their status';



CREATE OR REPLACE VIEW "public"."migration_status" AS
 SELECT "version",
    "description",
    "applied_at",
    "is_success",
    "execution_time_ms",
    "error_message",
        CASE
            WHEN "is_success" THEN '✅'::"text"
            ELSE '❌'::"text"
        END AS "status_icon"
   FROM "public"."schema_versions" "sv"
  ORDER BY "applied_at" DESC;


ALTER VIEW "public"."migration_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."schema_monitoring" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "operation" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "status" "text" NOT NULL,
    "details" "text",
    "performed_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "schema_monitoring_status_check" CHECK (("status" = ANY (ARRAY['SUCCESS'::"text", 'ERROR'::"text", 'WARNING'::"text"])))
);


ALTER TABLE "public"."schema_monitoring" OWNER TO "postgres";


COMMENT ON TABLE "public"."schema_monitoring" IS 'Tracks database operations and maintenance tasks';



CREATE TABLE IF NOT EXISTS "public"."system_health" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "metric_name" "text" NOT NULL,
    "metric_value" numeric NOT NULL,
    "metric_unit" "text",
    "tags" "jsonb",
    "recorded_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."system_health" OWNER TO "postgres";


COMMENT ON TABLE "public"."system_health" IS 'System performance and health metrics';



CREATE OR REPLACE VIEW "public"."system_metrics_summary" AS
 SELECT "metric_name",
    "count"(*) AS "measurement_count",
    "avg"("metric_value") AS "avg_value",
    "min"("metric_value") AS "min_value",
    "max"("metric_value") AS "max_value",
    "max"("recorded_at") AS "last_recorded"
   FROM "public"."system_health"
  GROUP BY "metric_name"
  ORDER BY ("max"("recorded_at")) DESC;


ALTER VIEW "public"."system_metrics_summary" OWNER TO "postgres";


ALTER TABLE ONLY "public"."case_contacts"
    ADD CONSTRAINT "case_contacts_case_id_contact_id_relationship_type_key" UNIQUE ("case_id", "contact_id", "relationship_type");



ALTER TABLE ONLY "public"."case_contacts"
    ADD CONSTRAINT "case_contacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cases"
    ADD CONSTRAINT "cases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact_communications"
    ADD CONSTRAINT "contact_communications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."hearings"
    ADD CONSTRAINT "hearings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."migration_logs"
    ADD CONSTRAINT "migration_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."schema_monitoring"
    ADD CONSTRAINT "schema_monitoring_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."schema_versions"
    ADD CONSTRAINT "schema_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."schema_versions"
    ADD CONSTRAINT "schema_versions_version_key" UNIQUE ("version");



ALTER TABLE ONLY "public"."system_health"
    ADD CONSTRAINT "system_health_pkey" PRIMARY KEY ("id");



CREATE INDEX "documents_case_id_idx" ON "public"."documents" USING "btree" ("case_id");



CREATE INDEX "documents_created_at_idx" ON "public"."documents" USING "btree" ("created_at");



CREATE INDEX "documents_efile_status_idx" ON "public"."documents" USING "btree" ("efile_status");



CREATE INDEX "documents_efile_timestamp_idx" ON "public"."documents" USING "btree" ("efile_timestamp");



CREATE UNIQUE INDEX "documents_envelope_filing_unique_idx" ON "public"."documents" USING "btree" ("envelope_id", "filing_id") WHERE (("envelope_id" IS NOT NULL) AND ("filing_id" IS NOT NULL));



CREATE INDEX "documents_envelope_id_idx" ON "public"."documents" USING "btree" ("envelope_id");



CREATE INDEX "documents_filing_id_idx" ON "public"."documents" USING "btree" ("filing_id");



CREATE INDEX "documents_status_idx" ON "public"."documents" USING "btree" ("status");



CREATE INDEX "documents_type_idx" ON "public"."documents" USING "btree" ("type");



CREATE INDEX "hearings_case_id_idx" ON "public"."hearings" USING "btree" ("case_id");



CREATE INDEX "hearings_hearing_date_idx" ON "public"."hearings" USING "btree" ("hearing_date");



CREATE INDEX "idx_case_contacts_case_id" ON "public"."case_contacts" USING "btree" ("case_id");



CREATE INDEX "idx_case_contacts_contact_id" ON "public"."case_contacts" USING "btree" ("contact_id");



CREATE INDEX "idx_case_contacts_primary" ON "public"."case_contacts" USING "btree" ("is_primary") WHERE ("is_primary" = true);



CREATE INDEX "idx_case_contacts_relationship" ON "public"."case_contacts" USING "btree" ("relationship_type");



CREATE INDEX "idx_contact_communications_case_id" ON "public"."contact_communications" USING "btree" ("case_id");



CREATE INDEX "idx_contact_communications_contact_id" ON "public"."contact_communications" USING "btree" ("contact_id");



CREATE INDEX "idx_contact_communications_date" ON "public"."contact_communications" USING "btree" ("communication_date");



CREATE INDEX "idx_contact_communications_follow_up" ON "public"."contact_communications" USING "btree" ("follow_up_required", "follow_up_date") WHERE ("follow_up_required" = true);



CREATE INDEX "idx_contact_communications_type" ON "public"."contact_communications" USING "btree" ("communication_type");



CREATE INDEX "idx_contacts_created_at" ON "public"."contacts" USING "btree" ("created_at");



CREATE INDEX "idx_contacts_email" ON "public"."contacts" USING "btree" ("email");



CREATE INDEX "idx_contacts_name" ON "public"."contacts" USING "btree" ("name");



CREATE INDEX "idx_contacts_role" ON "public"."contacts" USING "btree" ("role");



CREATE INDEX "idx_migration_logs_created_at" ON "public"."migration_logs" USING "btree" ("created_at");



CREATE INDEX "idx_migration_logs_level" ON "public"."migration_logs" USING "btree" ("log_level");



CREATE INDEX "idx_migration_logs_version" ON "public"."migration_logs" USING "btree" ("migration_version");



CREATE INDEX "idx_schema_monitoring_operation" ON "public"."schema_monitoring" USING "btree" ("operation");



CREATE INDEX "idx_schema_monitoring_performed_at" ON "public"."schema_monitoring" USING "btree" ("performed_at");



CREATE INDEX "idx_schema_monitoring_status" ON "public"."schema_monitoring" USING "btree" ("status");



CREATE INDEX "idx_schema_monitoring_table" ON "public"."schema_monitoring" USING "btree" ("table_name");



CREATE INDEX "idx_schema_versions_applied_at" ON "public"."schema_versions" USING "btree" ("applied_at");



CREATE INDEX "idx_schema_versions_success" ON "public"."schema_versions" USING "btree" ("is_success");



CREATE INDEX "idx_schema_versions_version" ON "public"."schema_versions" USING "btree" ("version");



CREATE INDEX "idx_system_health_metric" ON "public"."system_health" USING "btree" ("metric_name");



CREATE INDEX "idx_system_health_recorded_at" ON "public"."system_health" USING "btree" ("recorded_at");



CREATE OR REPLACE TRIGGER "update_case_contacts_updated_at" BEFORE UPDATE ON "public"."case_contacts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_cases_updated_at" BEFORE UPDATE ON "public"."cases" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contact_communications_updated_at" BEFORE UPDATE ON "public"."contact_communications" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contacts_updated_at" BEFORE UPDATE ON "public"."contacts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_documents_updated_at" BEFORE UPDATE ON "public"."documents" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_hearings_updated_at" BEFORE UPDATE ON "public"."hearings" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."case_contacts"
    ADD CONSTRAINT "case_contacts_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."case_contacts"
    ADD CONSTRAINT "case_contacts_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_communications"
    ADD CONSTRAINT "contact_communications_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."cases"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."contact_communications"
    ADD CONSTRAINT "contact_communications_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."hearings"
    ADD CONSTRAINT "hearings_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."cases"("id") ON DELETE CASCADE;



CREATE POLICY "Authenticated users can delete cases" ON "public"."cases" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Authenticated users can delete hearings" ON "public"."hearings" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Authenticated users can insert cases" ON "public"."cases" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Authenticated users can insert hearings" ON "public"."hearings" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Authenticated users can update cases" ON "public"."cases" FOR UPDATE TO "authenticated", "anon" USING (true);



CREATE POLICY "Authenticated users can update hearings" ON "public"."hearings" FOR UPDATE TO "authenticated", "anon" USING (true);



CREATE POLICY "Authenticated users can view all cases" ON "public"."cases" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Authenticated users can view all hearings" ON "public"."hearings" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can delete case contacts" ON "public"."case_contacts" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can delete contact communications" ON "public"."contact_communications" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can delete contacts" ON "public"."contacts" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can delete documents" ON "public"."documents" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can insert case contacts" ON "public"."case_contacts" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Users can insert contact communications" ON "public"."contact_communications" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Users can insert contacts" ON "public"."contacts" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Users can insert documents" ON "public"."documents" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Users can update case contacts" ON "public"."case_contacts" FOR UPDATE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can update contact communications" ON "public"."contact_communications" FOR UPDATE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can update contacts" ON "public"."contacts" FOR UPDATE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can update documents" ON "public"."documents" FOR UPDATE TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can view all case contacts" ON "public"."case_contacts" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can view all contact communications" ON "public"."contact_communications" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can view all contacts" ON "public"."contacts" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users can view all documents" ON "public"."documents" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."case_contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contact_communications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."hearings" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";































































































































































GRANT ALL ON FUNCTION "public"."create_case_with_transaction"("p_user_id" "uuid", "p_jurisdiction" "text", "p_county" "text", "p_case_type" "text", "p_attorney_id" "text", "p_reference_id" "text", "p_status" "text", "p_case_category" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_case_with_transaction"("p_user_id" "uuid", "p_jurisdiction" "text", "p_county" "text", "p_case_type" "text", "p_attorney_id" "text", "p_reference_id" "text", "p_status" "text", "p_case_category" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_case_with_transaction"("p_user_id" "uuid", "p_jurisdiction" "text", "p_county" "text", "p_case_type" "text", "p_attorney_id" "text", "p_reference_id" "text", "p_status" "text", "p_case_category" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_document_with_validation"("p_case_id" "uuid", "p_envelope_id" "text", "p_filing_id" "text", "p_file_name" "text", "p_doc_type" "text", "p_efile_status" "text", "p_efile_timestamp" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_document_with_validation"("p_case_id" "uuid", "p_envelope_id" "text", "p_filing_id" "text", "p_file_name" "text", "p_doc_type" "text", "p_efile_status" "text", "p_efile_timestamp" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_document_with_validation"("p_case_id" "uuid", "p_envelope_id" "text", "p_filing_id" "text", "p_file_name" "text", "p_doc_type" "text", "p_efile_status" "text", "p_efile_timestamp" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_schema_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_schema_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_schema_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_migration_event"("p_version" "text", "p_level" "text", "p_message" "text", "p_context" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_migration_event"("p_version" "text", "p_level" "text", "p_message" "text", "p_context" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_migration_event"("p_version" "text", "p_level" "text", "p_message" "text", "p_context" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."record_metric"("p_metric_name" "text", "p_metric_value" numeric, "p_metric_unit" "text", "p_tags" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."record_metric"("p_metric_name" "text", "p_metric_value" numeric, "p_metric_unit" "text", "p_tags" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_metric"("p_metric_name" "text", "p_metric_value" numeric, "p_metric_unit" "text", "p_tags" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_schema_integrity"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_schema_integrity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_schema_integrity"() TO "service_role";


















GRANT ALL ON TABLE "public"."case_contacts" TO "anon";
GRANT ALL ON TABLE "public"."case_contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."case_contacts" TO "service_role";



GRANT ALL ON TABLE "public"."cases" TO "anon";
GRANT ALL ON TABLE "public"."cases" TO "authenticated";
GRANT ALL ON TABLE "public"."cases" TO "service_role";



GRANT ALL ON TABLE "public"."contact_communications" TO "anon";
GRANT ALL ON TABLE "public"."contact_communications" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_communications" TO "service_role";



GRANT ALL ON TABLE "public"."contacts" TO "anon";
GRANT ALL ON TABLE "public"."contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."contacts" TO "service_role";



GRANT ALL ON TABLE "public"."documents" TO "anon";
GRANT ALL ON TABLE "public"."documents" TO "authenticated";
GRANT ALL ON TABLE "public"."documents" TO "service_role";



GRANT ALL ON TABLE "public"."hearings" TO "anon";
GRANT ALL ON TABLE "public"."hearings" TO "authenticated";
GRANT ALL ON TABLE "public"."hearings" TO "service_role";



GRANT ALL ON TABLE "public"."migration_logs" TO "anon";
GRANT ALL ON TABLE "public"."migration_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."migration_logs" TO "service_role";



GRANT ALL ON TABLE "public"."schema_versions" TO "anon";
GRANT ALL ON TABLE "public"."schema_versions" TO "authenticated";
GRANT ALL ON TABLE "public"."schema_versions" TO "service_role";



GRANT ALL ON TABLE "public"."migration_status" TO "anon";
GRANT ALL ON TABLE "public"."migration_status" TO "authenticated";
GRANT ALL ON TABLE "public"."migration_status" TO "service_role";



GRANT ALL ON TABLE "public"."schema_monitoring" TO "anon";
GRANT ALL ON TABLE "public"."schema_monitoring" TO "authenticated";
GRANT ALL ON TABLE "public"."schema_monitoring" TO "service_role";



GRANT ALL ON TABLE "public"."system_health" TO "anon";
GRANT ALL ON TABLE "public"."system_health" TO "authenticated";
GRANT ALL ON TABLE "public"."system_health" TO "service_role";



GRANT ALL ON TABLE "public"."system_metrics_summary" TO "anon";
GRANT ALL ON TABLE "public"."system_metrics_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."system_metrics_summary" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































RESET ALL;
