# QiC Update Session Data Solution

## Why Use This Solution?

Amazon Q in Connect sessions can store **custom data attributes** that enhance AI agent responses and provide context-aware assistance. This solution enables **dynamic session data updates** at runtime, allowing contact flows to inject customer information, conversation context, or business-specific data into Q in Connect sessions for more personalized and accurate AI responses.

## Overview

This AWS CloudFormation template deploys an AWS Lambda function that updates Amazon Connect Q in Connect (QiC) session data with custom key-value pairs. The Lambda function integrates with Amazon Connect contact flows to dynamically add contextual information to QiC sessions, supporting enhanced AI agent responses based on customer data and conversation context.

## Architecture

- **AWS Lambda Function**: Node.js 22.x runtime with inline code
- **AWS Identity and Access Management (IAM) Role**: Specific permissions for Wisdom session data updates and Connect contact access
- **Connect Integration**: Automatic association with Amazon Connect instance

## Prerequisites

- Amazon Connect instance with Q in Connect enabled
- QiC Assistant configured and active
- AI agents configured to utilize session data for enhanced responses
- AWS CloudFormation deployment permissions

## Parameters

| Parameter | Description | Where to Find | Format |
|-----------|-------------|---------------|--------|
| `AiAssistantARN` | ARN of the AWS Wisdom Assistant | AWS Command Line Interface (AWS CLI) or AWS CloudShell: `aws qconnect list-assistants` (use assistantArn from output) | `arn:aws:wisdom:region:account:assistant/id` |
| `ConnectInstanceARN` | ARN of the Amazon Connect Instance | AWS Console → Amazon Connect → Instances → Select your instance → Instance ARN in overview | `arn:aws:connect:region:account:instance/id` |

## Deployment

AWS Console
1. Upload template to AWS CloudFormation console [qic-agent-update-session-data.yaml](./qic-agent-update-session-data.yaml)
2. Provide required parameters
3. Deploy with IAM capability acknowledgment

## Usage

### Contact Flow Integration

The solution integrates with Amazon Connect contact flows to update session data with custom key-value pairs.

#### Required Contact Flow Blocks (in order):

1. **Amazon Q Connect** - Initialize Q in Connect session

2. **Invoke AWS Lambda Function** - Update session data
   - Function ARN: Use the deployed Lambda function ARN from stack outputs
   - Add Lambda parameters as key-value pairs:
     - `key1`: First data key (e.g., `customer_tier`)
     - `value1`: First data value (e.g., `premium`)
     - `key2`: Second data key (e.g., `account_type`)
     - `value2`: Second data value (e.g., `business`)

#### Key-Value Pair Format
The function expects parameters in the format `keyN` and `valueN` where N is a number:
- `key1` / `value1`: First key-value pair
- `key2` / `value2`: Second key-value pair
- `key3` / `value3`: Third key-value pair (and so on)

Example parameters:
```
key1: customer_tier
value1: premium
key2: account_balance
value2: 15000
key3: last_interaction
value3: billing_inquiry
```

### Environment Variables
The Lambda automatically configures:
- `AI_ASSISTANT_ID`: Extracted from AiAssistantARN parameter
- `CONNECT_INSTANCE_ID`: Extracted from ConnectInstanceARN parameter

## Outputs

| Output | Description |
|--------|-------------|
| `LambdaFunctionArn` | ARN of the deployed AWS Lambda function |
| `LambdaFunctionName` | Name of the AWS Lambda function |

## Response Format

Success response:
```json
{
  "statusCode": 200
}
```

Error response:
```json
{
  "error": "Error message"
}
```

## Monitoring

- Amazon CloudWatch logs available under `/aws/lambda/{stackname}-qic-session`
- Structured logging includes:
  - Key-value pairs being updated
  - Session update commands
  - Error tracking and debugging information

## Performance Considerations

### API Rate Limits
This solution makes API calls to Amazon Q in Connect for each contact:
- `UpdateSessionData` - to add custom data to the session
- `DescribeContact` - to retrieve the Q in Connect session ARN

**Important**: Amazon Q in Connect APIs have rate limits. For high-volume contact centers, consider implementing:

### Recommended Optimizations
1. **Batch Updates**: Group multiple key-value pairs in single Lambda invocation
2. **Caching Strategy**: Cache session ARNs to reduce DescribeContact calls
3. **Error Handling**: Implement retry logic for transient API failures

## Security

- AWS IAM permissions configured following principle of least privilege
- Resource-level access controls with specific action limitations
- No embedded credentials or sensitive configuration data