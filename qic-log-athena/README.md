# Q in Connect CloudWatch Logs to Athena Analytics

This CloudFormation template sets up a complete pipeline to stream Q in Connect logs from CloudWatch to Athena for analytics and visualization.

## Overview

The template creates a comprehensive logging and analytics infrastructure that captures Q in Connect events from CloudWatch Logs, transforms them via Lambda, stores them in S3, and makes them queryable through Athena for business intelligence and operational monitoring.

## Resources Created

- **S3 Bucket**: Stores processed Q in Connect logs with versioning enabled
- **Glue Database & Table**: Provides schema for Q in Connect log structure
- **Lambda Function**: Transforms CloudWatch Logs format to clean JSON
- **Kinesis Firehose**: Streams logs from CloudWatch to S3 with transformation
- **CloudWatch Subscription Filter**: Automatically captures all Q in Connect logs
- **IAM Roles**: Proper permissions for all services

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `LogGroupName` | CloudWatch log group name for Q in Connect logs | `/aws/connect/qic-logs` | No |
| `S3BucketName` | S3 bucket prefix for storing logs (must be globally unique) | `qic-logs-athena-bucket` | No |

## Deployment

### Prerequisites
- Existing Q in Connect instance generating logs
- CloudWatch log group with Q in Connect logs

### Deploy via Console
1. Open AWS CloudFormation Console
2. Create new stack
3. Upload `qic-logs-athena.yaml`
4. Provide your Q in Connect log group name
5. Deploy with IAM capabilities

## Outputs

- `S3Bucket`: S3 bucket name for Q in Connect logs
- `AthenaDatabase`: Athena database name (`qic_logs_db`)
- `AthenaTable`: Athena table name (`qic_logs`)
- `SampleQuery`: Basic Athena query to get started

## Log Schema

The Athena table contains the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `assistant_id` | string | Unique identifier for the Q in Connect assistant |
| `event_timestamp` | bigint | Unix timestamp in milliseconds |
| `event_type` | string | Type of event (e.g., TRANSCRIPT_SELF_SERVICE_MESSAGE) |
| `session_id` | string | Unique session identifier |
| `utterance` | string | Customer or agent message |
| `prompt` | string | AI model prompt (JSON format) |
| `prompt_type` | string | Type of prompt used |
| `completion` | string | AI model response (JSON format) |
| `model_id` | string | AI model identifier |
| `session_message_id` | string | Unique message identifier |
| `parsed_response` | string | Processed response text |

## Sample Analytics Queries

Use the provided `athena-queries-final.sql` file for comprehensive analytics including:

- **Session Analysis**: Duration, interaction counts, success rates
- **Assistant Performance**: Failure rates, model usage, traffic patterns
- **Customer Insights**: Common queries, failed interactions, conversation flows
- **Operational Monitoring**: Real-time metrics, hourly patterns, error tracking

### Quick Start Queries
```sql
-- Total records
SELECT COUNT(*) as total_records FROM qic_logs_db.qic_logs;

-- Recent activity
SELECT * FROM qic_logs_db.qic_logs ORDER BY event_timestamp DESC LIMIT 10;

-- Failure rate analysis
SELECT 
    COUNT(*) as total_interactions,
    COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) as failed_responses,
    ROUND(COUNT(CASE WHEN parsed_response = 'I don''t have an answer' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_pct
FROM qic_logs_db.qic_logs;
```

## QuickSight Integration

Connect Amazon QuickSight to your Athena table for visual dashboards:

1. **Create QuickSight Dataset**: Connect to Athena → Select `qic_logs_db.qic_logs`
2. **Build Dashboards**: Use sample queries as basis for visualizations
3. **Key Metrics**: Session success rates, assistant performance, customer satisfaction
4. **Real-time Monitoring**: Set up refresh schedules for operational dashboards

## Data Pipeline Flow

```
Q in Connect Logs → CloudWatch Logs → Subscription Filter → Kinesis Firehose → Lambda Transform → S3 → Athena → QuickSight
```

## Permissions Required

The deployment requires permissions for:
- `s3:*` (for bucket operations)
- `glue:*` (for database and table creation)
- `firehose:*` (for delivery stream)
- `lambda:*` (for transformation function)
- `logs:*` (for subscription filter)
- `iam:*` (for role creation)

## Cost Considerations

Costs depend on:
- Q in Connect log volume
- S3 storage for processed logs
- Athena query frequency and data scanned
- Lambda transformation executions
- Kinesis Firehose delivery charges

## Monitoring and Troubleshooting

- **CloudWatch Metrics**: Monitor Firehose delivery success rates
- **Lambda Logs**: Check transformation function for errors
- **S3 Objects**: Verify logs are being written to S3
- **Athena Queries**: Test with simple queries first

## Cleanup

Delete the CloudFormation stack to remove all resources:
```bash
aws cloudformation delete-stack --stack-name qic-logs-athena
```

**Note**: S3 bucket contents must be deleted manually before stack deletion.

## Files Included

- `qic-logs-athena.yaml`: Main CloudFormation template
- `athena-queries-final.sql`: Comprehensive analytics queries and views
- `README.md`: This documentation file