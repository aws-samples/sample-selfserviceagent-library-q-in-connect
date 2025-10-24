# QiC Agent Lambda Invocation Solution

## Why Use This Solution?

This solution enables **direct Lambda invocation of Amazon Lex bots with Q in Connect integration**. It allows contact flows to programmatically invoke Lex bots while maintaining the Q in Connect session context, enabling AI-powered responses without requiring traditional voice or chat bot interactions.

## Overview

This AWS CloudFormation template deploys an AWS Lambda function that initializes and invokes Amazon Lex bots using the RecognizeText API. The Lambda function integrates with Amazon Connect contact flows and maintains Q in Connect session context, allowing for programmatic AI agent interactions based on contact attributes and routing conditions.

## Architecture

- **AWS Lambda Function**: Node.js 22.x runtime with inline code
- **AWS Identity and Access Management (IAM) Role**: Specific permissions for Lex RecognizeText and Connect contact access
- **Lex Integration**: Direct API invocation with Q in Connect session context

## Prerequisites

- Amazon Connect instance with Q in Connect enabled
- QiC Assistant configured and active
- Amazon Lex bot with Q in Connect intent configured
- AWS CloudFormation deployment permissions

## Parameters

| Parameter | Description | Where to Find | Format |
|-----------|-------------|---------------|--------|
| `LexBotId` | ID of the Amazon Lex Bot | AWS Console → Amazon Lex → Bots → Select your bot → Bot ID | `12345678-1234-1234-1234-123456789012` |
| `LexBotAliasId` | Alias ID of the Amazon Lex Bot | AWS Console → Amazon Lex → Bots → Aliases → Alias ID | `TSTALIASID` (default) |
| `LexLocaleId` | Locale ID for the Lex Bot | AWS Console → Amazon Lex → Bots → Languages | `en_US` (default) |
| `ConnectInstanceId` | Amazon Connect Instance ID | AWS Console → Amazon Connect → Instances → Instance ID | `12345678-1234-1234-1234-123456789012` |

## Deployment

AWS Console
1. Upload template to AWS CloudFormation console [qic-agent-lambda-invocation.yaml](./qic-agent-lambda-invocation.yaml)
2. Provide required parameters
3. Deploy with IAM capability acknowledgment

## Usage

### Contact Flow Integration

The solution integrates with Amazon Connect contact flows through Lambda function invocation.

#### Required Contact Flow Blocks (in order):

1. **Amazon Q Connect** - Initialize Q in Connect session

2. **Invoke AWS Lambda Function** - Invoke Lex bot programmatically
   - Function ARN: Use the deployed Lambda function ARN from stack outputs
   - Add Lambda parameter: `summary` with the text to process
   - Example: `"Customer needs help with billing"`

#### Lambda Function Parameters
The function expects a `summary` parameter containing the text to send to the Lex bot:
- Parameter name: `summary`
- Parameter value: Text string to process through Lex and Q in Connect

### Environment Variables
The Lambda automatically configures:
- `LEX_BOT_ID`: From LexBotId parameter
- `LEX_BOT_ALIAS_ID`: From LexBotAliasId parameter  
- `LEX_LOCALE_ID`: From LexLocaleId parameter
- `CONNECT_INSTANCE_ID`: From ConnectInstanceId parameter

## Outputs

| Output | Description |
|--------|-------------|
| `LambdaFunctionArn` | ARN of the deployed AWS Lambda function |
| `LambdaFunctionName` | Name of the AWS Lambda function |

## Response Format

Success response:
```json
{
  "statusCode": 200,
  "lexqicResponse": "AI-generated response from Q in Connect"
}
```

Error response:
```json
{
  "statusCode": 500,
  "body": {
    "error": "Error message"
  }
}
```

## Monitoring

- Amazon CloudWatch logs available under `/aws/lambda/{stackname}-lex-qic-lambda`
- Detailed logging includes:
  - Lex command structure
  - Lex response data
  - Q in Connect session ARN
  - Error tracking

## Security

- AWS IAM permissions configured following principle of least privilege
- Resource-level access controls for Lex bot aliases
- No embedded credentials or sensitive configuration data