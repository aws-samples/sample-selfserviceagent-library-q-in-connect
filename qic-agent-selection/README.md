# QiC Self service AI Agent Selection Solution

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
| `AiAssistantARN` | ARN of the AWS Wisdom Assistant | AWS Command Line Interface (AWS CLI) or AWS CloudShell: `aws qconnect list-assistants` (use assistantArn from output) | `arn:aws:wisdom:region:account:assistant/id` |
| `ConnectInstanceARN` | ARN of the Amazon Connect Instance | AWS Console → Amazon Connect → Instances → Select your instance → Instance ARN in overview | `arn:aws:connect:region:account:instance/id` |

## Deployment

AWS Console
1. Upload template to AWS CloudFormation console
2. Provide required parameters
3. Deploy with IAM capability acknowledgment

## Usage

### Contact Flow Integration

The solution integrates with Amazon Connect contact flows through a specific sequence of blocks. Use the provided sample contact flow [qic-agent-selection-contact-flow-sample.json](./contact-flow/qic-agent-selection-contact-flow-sample.json) as a reference.

#### Required Contact Flow Blocks (in order):

1. **Amazon Q Connect** - block to Initialize Q in Connect session and add Domain 

2. **Invoke AWS Lambda Function** - Select AI agent dynamically
   - Function ARN: Use the deployed Lambda function ARN from stack outputs
   - Add Lambda attribute: `AI_AGENT_ID` with your desired agent ID (format: `agent-id:version`)
   - Example: `a3a98286-b008-48e0-8ea6-be1722e468ea:1`

3. **Connect to Amazon Lex Bot** - Handle customer interaction
   - Add your Amazon Lex bot with Q in Connect intent, It would now use the Self Service Agent Id. 

#### Sample Contact Flow
Import the provided [qic-agent-selection-contact-flow-sample.json](./contact-flow/qic-agent-selection-contact-flow-sample.json) and update:
- Assistant ARN in Amazon Q Connect block
- AWS Lambda function ARN in Invoke Lambda Function block
- AI_AGENT_ID parameter with your specific agent ID
- Amazon Lex bot configuration

#### AI Agent ID Format
The `AI_AGENT_ID` parameter should follow the format: `{agent-id}:{version}`
- Get agent ID from: `aws qconnect list-ai-agents --assistant-id {your-assistant-id}`
- Use version `1` for the latest version

### Environment Variables
The Lambda automatically configures:
- `AI_ASSISTANT_ID`: Extracted from AiAssistantARN parameter
- `CONNECT_INSTANCE_ID`: Extracted from ConnectInstanceARN parameter
- `DEBUG_LOG`: Configured for detailed troubleshooting with structured logging

## Outputs

| Output | Description |
|--------|-------------|
| `LambdaFunctionArn` | ARN of the deployed AWS Lambda function |
| `LambdaFunctionName` | Name of the AWS Lambda function |

## Monitoring

- Amazon CloudWatch logs available under `/aws/lambda/qic-agent-select-lambda`
- Debug logging configured with structured JSON format supporting:
  - Timestamp-based event tracking
  - Function execution states
  - Error categorization
  - Performance metrics

## Security

- AWS IAM permissions configured following principle of least privilege
- Resource-level access controls with specific action limitations
- No embedded credentials or sensitive configuration data
```

Links to reference documentation:
1. Security Messaging Guidelines - https://w.amazon.com/bin/view/AWS_IT_Security/GrowthStrategies/How_To_Create_Content_About_Security/Guidelines/
2. Service Name branding - https://w.amazon.com/bin/view/AWSDocs/editing/service-names/

