-- Q in Connect Athena Views for QuickSight Dashboard
-- Run these in Athena to create views that can be used directly in QuickSight

-- 1. DAILY METRICS VIEW
CREATE VIEW qic_daily_metrics AS
SELECT 
    DATE(from_unixtime(event_timestamp/1000)) as log_date,
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(DISTINCT assistant_id) as active_assistants,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct
FROM qic_logs_db.qic_logs
GROUP BY DATE(from_unixtime(event_timestamp/1000)), event_type;

-- 2. HOURLY TRAFFIC VIEW
CREATE VIEW qic_hourly_traffic AS
SELECT 
    EXTRACT(hour FROM from_unixtime(event_timestamp/1000)) as hour_of_day,
    DATE(from_unixtime(event_timestamp/1000)) as log_date,
    COUNT(*) as total_events,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct
FROM qic_logs_db.qic_logs
GROUP BY EXTRACT(hour FROM from_unixtime(event_timestamp/1000)), DATE(from_unixtime(event_timestamp/1000));

-- 3. ASSISTANT PERFORMANCE VIEW
CREATE VIEW qic_assistant_performance AS
SELECT 
    assistant_id,
    COUNT(DISTINCT session_id) as sessions_handled,
    COUNT(*) as total_events,
    COUNT(CASE WHEN event_type = 'TRANSCRIPT_SELF_SERVICE_MESSAGE' THEN 1 END) as transcript_messages,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct,
    COUNT(DISTINCT model_id) as models_used,
    AVG(LENGTH(COALESCE(utterance, ''))) as avg_utterance_length
FROM qic_logs_db.qic_logs
GROUP BY assistant_id;

-- 4. SESSION SUMMARY VIEW
CREATE VIEW qic_session_summary AS
SELECT 
    session_id,
    assistant_id,
    COUNT(*) as total_messages,
    MIN(from_unixtime(event_timestamp/1000)) as session_start,
    MAX(from_unixtime(event_timestamp/1000)) as session_end,
    (MAX(event_timestamp) - MIN(event_timestamp))/1000 as duration_seconds,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    COUNT(DISTINCT session_message_id) as unique_messages,
    COUNT(DISTINCT model_id) as models_used,
    CASE 
        WHEN COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) = 0 THEN 'Success'
        ELSE 'Failed'
    END as session_status
FROM qic_logs_db.qic_logs
GROUP BY session_id, assistant_id;

-- 5. MODEL PERFORMANCE VIEW
CREATE VIEW qic_model_performance AS
SELECT 
    model_id,
    COUNT(*) as usage_count,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(DISTINCT assistant_id) as assistants_using,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct,
    AVG(LENGTH(COALESCE(prompt, ''))) as avg_prompt_length,
    AVG(LENGTH(COALESCE(completion, ''))) as avg_completion_length,
    AVG(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE)) as avg_latency_ms,
    MIN(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE)) as min_latency_ms,
    MAX(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE)) as max_latency_ms,
    APPROX_PERCENTILE(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE), 0.5) as median_latency_ms,
    APPROX_PERCENTILE(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE), 0.95) as p95_latency_ms
FROM "qic-be2809e3-330d-4efc-aae3-9e05451f7822_qic_logs_db"."qic-be2809e3-330d-4efc-aae3-9e05451f7822_qic_logs"
WHERE model_id IS NOT NULL
GROUP BY model_id;

-- 11. MODEL LATENCY PERFORMANCE VIEW
CREATE VIEW qic_model_latency_performance AS
SELECT 
    model_id,
    DATE(from_unixtime(event_timestamp/1000)) as log_date,
    COUNT(*) as request_count,
    AVG(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE)) as avg_latency_ms,
    MIN(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE)) as min_latency_ms,
    MAX(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE)) as max_latency_ms,
    APPROX_PERCENTILE(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE), 0.5) as median_latency_ms,
    APPROX_PERCENTILE(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE), 0.95) as p95_latency_ms,
    APPROX_PERCENTILE(CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE), 0.99) as p99_latency_ms,
    COUNT(CASE WHEN CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE) > 5000 THEN 1 END) as slow_requests,
    ROUND(COUNT(CASE WHEN CAST(JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') AS DOUBLE) > 5000 THEN 1 END) * 100.0 / COUNT(*), 2) as slow_request_pct
FROM "qic-be2809e3-330d-4efc-aae3-9e05451f7822_qic_logs_db"."qic-be2809e3-330d-4efc-aae3-9e05451f7822_qic_logs"
WHERE model_id IS NOT NULL 
    AND JSON_EXTRACT_SCALAR(completion, '$.metrics.latencyMs') IS NOT NULL
GROUP BY model_id, DATE(from_unixtime(event_timestamp/1000));

-- 6. CUSTOMER INTERACTIONS VIEW
CREATE VIEW qic_customer_interactions AS
SELECT 
    session_id,
    assistant_id,
    from_unixtime(event_timestamp/1000) as event_time,
    DATE(from_unixtime(event_timestamp/1000)) as event_date,
    EXTRACT(hour FROM from_unixtime(event_timestamp/1000)) as hour_of_day,
    event_type,
    CASE 
        WHEN utterance LIKE '%[CUSTOMER]%' THEN TRIM(REGEXP_REPLACE(utterance, '^\[CUSTOMER\]\s*', ''))
        ELSE utterance
    END as customer_message,
    parsed_response,
    CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 ELSE 0 END as is_failed_response,
    model_id,
    prompt_type
FROM qic_logs_db.qic_logs
WHERE utterance IS NOT NULL;

-- 7. REAL-TIME KPI VIEW
CREATE VIEW qic_realtime_kpi AS
SELECT 
    'Last Hour' as time_period,
    COUNT(*) as total_events,
    COUNT(DISTINCT session_id) as active_sessions,
    COUNT(DISTINCT assistant_id) as active_assistants,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct
FROM qic_logs_db.qic_logs
WHERE event_timestamp > to_unixtime(current_timestamp - interval '1' hour) * 1000

UNION ALL

SELECT 
    'Last 24 Hours' as time_period,
    COUNT(*) as total_events,
    COUNT(DISTINCT session_id) as active_sessions,
    COUNT(DISTINCT assistant_id) as active_assistants,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct
FROM qic_logs_db.qic_logs
WHERE event_timestamp > to_unixtime(current_timestamp - interval '1' day) * 1000

UNION ALL

SELECT 
    'Last 7 Days' as time_period,
    COUNT(*) as total_events,
    COUNT(DISTINCT session_id) as active_sessions,
    COUNT(DISTINCT assistant_id) as active_assistants,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct
FROM qic_logs_db.qic_logs
WHERE event_timestamp > to_unixtime(current_timestamp - interval '7' day) * 1000;

-- 8. SESSION DURATION BUCKETS VIEW
CREATE VIEW qic_session_duration_buckets AS
WITH session_stats AS (
    SELECT 
        session_id,
        assistant_id,
        COUNT(*) as interaction_count,
        (MAX(event_timestamp) - MIN(event_timestamp))/1000 as duration_seconds,
        COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_count
    FROM qic_logs_db.qic_logs
    GROUP BY session_id, assistant_id
)
SELECT 
    CASE 
        WHEN duration_seconds < 30 THEN '0-30s'
        WHEN duration_seconds < 60 THEN '30-60s'
        WHEN duration_seconds < 300 THEN '1-5min'
        WHEN duration_seconds < 900 THEN '5-15min'
        ELSE '15min+'
    END as duration_bucket,
    COUNT(*) as session_count,
    AVG(interaction_count) as avg_interactions,
    AVG(duration_seconds) as avg_duration_seconds,
    SUM(failed_count) as total_failures,
    ROUND(SUM(failed_count) * 100.0 / COUNT(*), 2) as failure_rate_pct
FROM session_stats
WHERE duration_seconds >= 0
GROUP BY 1;

-- 9. TOP FAILED QUERIES VIEW
CREATE VIEW qic_top_failed_queries AS
SELECT 
    CASE 
        WHEN utterance LIKE '%[CUSTOMER]%' THEN TRIM(REGEXP_REPLACE(utterance, '^\[CUSTOMER\]\s*', ''))
        ELSE utterance
    END as customer_query,
    COUNT(*) as failure_count,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(DISTINCT assistant_id) as assistants_involved
FROM qic_logs_db.qic_logs
WHERE parsed_response = 'I don''t have an answer'
    AND utterance IS NOT NULL 
    AND utterance != ''
    AND LENGTH(utterance) > 10
GROUP BY CASE 
    WHEN utterance LIKE '%[CUSTOMER]%' THEN TRIM(REGEXP_REPLACE(utterance, '^\[CUSTOMER\]\s*', ''))
    ELSE utterance
END
HAVING COUNT(*) > 1
ORDER BY failure_count DESC;

-- 10. EVENT TYPE DISTRIBUTION VIEW
CREATE VIEW qic_event_type_distribution AS
SELECT 
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(DISTINCT assistant_id) as assistants_involved,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage,
    MIN(from_unixtime(event_timestamp/1000)) as first_seen,
    MAX(from_unixtime(event_timestamp/1000)) as last_seen
FROM qic_logs_db.qic_logs
GROUP BY event_type;