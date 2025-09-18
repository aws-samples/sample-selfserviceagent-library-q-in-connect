# QiC Self service AI Agent Selection Solution v2

## Why Use This Solution?

The Amazon Connect console currently provides configuration for **one default Self service AI agent** per QiC assistant. This solution facilitates **dynamic Self service AI agent selection** at runtime, allowing contact flows to use specialized AI agents for specific use cases such as technical support, billing inquiries, or product information based on defined routing rules and operational requirements.

## Overview

This AWS CloudFormation template deploys an AWS Lambda function that dynamically selects and configures AI agents for Amazon Connect Q in Connect (QiC) sessions. The Lambda function integrates with Amazon Connect contact flows to update QiC sessions with specific AI agent configurations, supporting dynamic agent selection based on defined contact attributes and routing conditions.

## Architecture

- **AWS Lambda Function**: Node.js 22.x runtime with inline code
- **AWS Identity and Access Management (IAM) Role**: Specific permissions for Wisdom session updates and Connect contact access
- **Connect Integration**: Automatic association with Amazon Connect instance

## Prerequisites

- Amazon Connect instance with Q in Connect enabled
- QiC Assistant configured and active
- Custom Self Service AI Agent, with configured response templates and interaction patterns
- Amazon Lex bot with Q In Connect Intent 
- AWS CloudFormation deployment permissions

## Parameters

| Parameter | Description | Where to Find | Format |
|-----------|-------------|---------------|--------|
| `AiAssistantId` | ID of the AWS Wisdom Assistant | AWS Command Line Interface (AWS CLI) or AWS CloudShell: `aws qconnect list-assistants` (use assistantId from output) | `12345678-1234-1234-1234-123456789012` |
| `ConnectInstanceArn` | ARN of the Amazon Connect Instance | AWS Console → Amazon Connect → Instances → Select your instance → Instance ARN in overview | `arn:aws:connect:region:account:instance/id` |

## Deployment

AWS Console
1. Upload template to AWS CloudFormation console [qic-agent-selection-lambda-v2.yaml](./qic-agent-selection-lambda-v2.yaml)
2. Provide required parameters
3. Deploy with IAM capability acknowledgment

## Usage

### Contact Flow Integration

The solution integrates with Amazon Connect contact flows through a specific sequence of blocks.

#### Required Contact Flow Blocks (in order):

1. **Amazon Q Connect** - block to Initialize Q in Connect session and add Domain 

2. **Invoke AWS Lambda Function** - Select AI agent dynamically
   - Function ARN: Use the deployed Lambda function ARN from stack outputs
   - Add Lambda attribute: `AI_AGENT_NAME` with your desired agent name
   - Example: `CustomerServiceAgent`

3. **Connect to Amazon Lex Bot** - Handle customer interaction
   - Add your Amazon Lex bot with Q in Connect intent, It would now use the Self Service Agent. 

#### AI Agent Name Format
The `AI_AGENT_NAME` parameter should be the exact name of your AI agent as configured in Q in Connect:
- Get agent names from: `aws qconnect list-ai-agents --assistant-id {your-assistant-id}`
- Use the exact name value from the response

### Environment Variables
The Lambda automatically configures:
- `AI_ASSISTANT_ID`: From AiAssistantId parameter
- `CONNECT_INSTANCE_ID`: Extracted from ConnectInstanceArn parameter
- `DEBUG_LOG`: Configured for detailed troubleshooting with structured logging

## Outputs

| Output | Description |
|--------|-------------|
| `LambdaFunctionArn` | ARN of the deployed AWS Lambda function |
| `LambdaFunctionName` | Name of the AWS Lambda function |
| `ConnectInstanceId` | Connect Instance ID extracted from ARN |

## Monitoring

- Amazon CloudWatch logs available under `/aws/lambda/{stackname}-agent-selection-lambda`
- Debug logging configured with structured JSON format supporting:
  - Timestamp-based event tracking
  - Function execution states
  - Error categorization
  - Performance metrics

## Security

- AWS IAM permissions configured following principle of least privilege
- Resource-level access controls with specific action limitations
- No embedded credentials or sensitive configuration data