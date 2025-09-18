# Sample Self-Service Agent Library for Amazon Q in Connect

This library provides sample implementations and utilities for building self-service AI agents with Amazon Q in Connect.

## Components

### QiC Agent Selection Lambda
Enables dynamic selection of AI agents during contact sessions, overcoming the limitation where Amazon Connect console only allows one default AI agent per assistant.

**For detailed setup and usage instructions, see:** [qic-agent-selection README](./qic-agent-selection/README.md)

### QiC Agent Selection Lambda V2
Enables dynamic selection of AI agents during contact sessions, overcoming the limitation where Amazon Connect console only allows one default AI agent per assistant.
This version uses Agent Name instead of Agent Id:Version Id
**For detailed setup and usage instructions, see:** [qic-agent-selection-v2 README](./qic-agent-selection-v2/README.md)

### QiC Assistant CloudWatch Logging
Sets up comprehensive logging infrastructure for AWS Wisdom Assistant using CloudWatch Logs delivery. Captures assistant events and stores them for monitoring, debugging, and analytics.

**For detailed setup and usage instructions, see:** [qic-log README](./qic-log/README.md)

## Prerequisites

- Amazon Connect instance with Q in Connect enabled
- Multiple AI agents configured in your Q in Connect assistant
- AWS CLI configured with appropriate permissions

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

