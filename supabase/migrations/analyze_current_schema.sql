-- Analyze Current Supabase Schema
-- Created: 2025-01-20
-- Purpose: Identify all views and functions for optimization

-- 1. List all views in the public schema
SELECT 
    schemaname,
    viewname,
    viewowner,
    definition
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;

-- 2. List all functions in the public schema
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_catalog.pg_get_function_result(p.oid) AS result_type,
    pg_catalog.pg_get_function_arguments(p.oid) AS arguments,
    CASE 
        WHEN p.prosecdef THEN 'SECURITY DEFINER'
        ELSE 'SECURITY INVOKER'
    END AS security_type,
    p.provolatile AS volatility,
    p.procost AS estimated_cost,
    p.prorows AS estimated_rows
FROM pg_proc p
LEFT JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
    AND p.prokind = 'f'
ORDER BY p.proname;

-- 3. Check for duplicate or similar views
WITH view_signatures AS (
    SELECT 
        viewname,
        regexp_replace(definition, '\s+', ' ', 'g') as normalized_definition
    FROM pg_views
    WHERE schemaname = 'public'
)
SELECT 
    v1.viewname AS view1,
    v2.viewname AS view2,
    similarity(v1.normalized_definition, v2.normalized_definition) AS similarity_score
FROM view_signatures v1
CROSS JOIN view_signatures v2
WHERE v1.viewname < v2.viewname
    AND similarity(v1.normalized_definition, v2.normalized_definition) > 0.5
ORDER BY similarity_score DESC;

-- 4. Analyze table sizes and row counts
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS indexes_size,
    n_live_tup AS row_count,
    n_dead_tup AS dead_rows
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 5. Check for missing indexes on foreign keys
SELECT 
    conrelid::regclass AS table_name,
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition,
    'CREATE INDEX idx_' || conrelid::regclass || '_' || 
        substring(pg_get_constraintdef(oid) from 'REFERENCES (\w+)') || 
        ' ON ' || conrelid::regclass || ' (' || 
        substring(pg_get_constraintdef(oid) from '\(([^)]+)\)') || ');' AS suggested_index
FROM pg_constraint
WHERE contype = 'f'
    AND NOT EXISTS (
        SELECT 1
        FROM pg_index
        WHERE pg_index.indrelid = pg_constraint.conrelid
            AND pg_index.indkey[0] = ANY(pg_constraint.conkey)
    );

-- 6. Identify potentially slow views (with multiple joins or subqueries)
SELECT 
    viewname,
    LENGTH(definition) as definition_length,
    (LENGTH(definition) - LENGTH(REPLACE(UPPER(definition), 'JOIN', ''))) / 4 AS join_count,
    (LENGTH(definition) - LENGTH(REPLACE(UPPER(definition), 'SELECT', ''))) / 6 AS subquery_count,
    CASE 
        WHEN definition ILIKE '%NOT EXISTS%' THEN 'Uses NOT EXISTS'
        WHEN definition ILIKE '%IN (%' THEN 'Uses IN clause'
        WHEN definition ILIKE '%DISTINCT%' THEN 'Uses DISTINCT'
        ELSE 'Standard'
    END AS query_patterns
FROM pg_views
WHERE schemaname = 'public'
ORDER BY join_count DESC, subquery_count DESC;

-- 7. Check for unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
    AND idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- 8. Identify tables without primary keys
SELECT 
    n.nspname AS schema_name,
    c.relname AS table_name
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
    AND n.nspname = 'public'
    AND NOT EXISTS (
        SELECT 1
        FROM pg_constraint con
        WHERE con.conrelid = c.oid
            AND con.contype = 'p'
    );

-- 9. Check for tables with too many indexes
SELECT 
    schemaname,
    tablename,
    COUNT(*) AS index_count,
    STRING_AGG(indexname, ', ') AS indexes
FROM pg_indexes
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
HAVING COUNT(*) > 5
ORDER BY index_count DESC;

-- 10. Analyze RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;