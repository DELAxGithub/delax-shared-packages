# Issue Routing System

An intelligent GitHub issue routing system that automatically classifies and routes issues from a central router repository to appropriate target repositories using rule-based logic and AI-powered classification.

## Features

- **Intelligent Routing**: Combines rule-based matching with AI-powered classification
- **Duplicate Detection**: Prevents duplicate issues using Slack permalinks and content hashing
- **GitHub Projects Integration**: Automatically adds routed issues to GitHub Projects v2
- **Multi-Repository Support**: Route issues across multiple repositories in your organization
- **Customizable Rules**: YAML-based configuration for easy customization
- **GitHub Actions Integration**: Fully automated workflow using GitHub Actions

## Architecture Overview

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Slack    │───▶│    Router    │───▶│  Classification │───▶│ Target Repos &  │
│  /Issues    │    │ Repository   │    │   & Routing     │    │   Projects v2   │
└─────────────┘    └──────────────┘    └─────────────────┘    └─────────────────┘
                           │                      │
                           ▼                      ▼
                   ┌──────────────┐    ┌─────────────────┐
                   │   GitHub     │    │   AI-Powered    │
                   │   Actions    │    │ Classification  │
                   └──────────────┘    └─────────────────┘
```

## Quick Start

### 1. Installation

```bash
# Clone the repository
git clone [repository-url]
cd automation/routing-system

# Install dependencies
npm install

# Build the project
npm run build
```

### 2. Configuration

Copy the sample configuration and customize it for your organization:

```bash
cp config/routing.yml.example config/routing.yml
```

Edit `config/routing.yml` to define your routing rules:

```yaml
defaults:
  repo: "your-org/inbox"
  labels: ["triage", "auto-routed"]
  project:
    org: "your-org"
    number: 12

rules:
  - when:
      keywords: ["iOS", "Swift", "Xcode"]
      channels: ["#ios-dev"]
    route:
      repo: "your-org/ios-app"
      labels: ["ios", "mobile"]
      assignees: ["ios-team-lead"]
      priority: "high"
```

### 3. Setup GitHub Actions

1. Copy the router workflow to your router repository:
   ```bash
   cp workflows/router.yml .github/workflows/route-issues.yml
   ```

2. Copy the triage workflow to your target repositories:
   ```bash
   cp workflows/triage.yml [target-repo]/.github/workflows/triage-routed-issues.yml
   ```

### 4. Configure Secrets

Add the following secrets to your repositories:

**Router Repository:**
- `ROUTING_TOKEN`: GitHub token with access to target repositories
- `OPENAI_API_KEY`: OpenAI API key for AI classification (optional)

**Target Repositories:**
- `GITHUB_TOKEN`: Default token (automatically provided)
- `PROJECTS_TOKEN`: Token for cross-org project access (if needed)

### 5. Test the Setup

Run the setup script for guided configuration:

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## Usage

### Basic Usage

Create an issue in your router repository, and the system will automatically:

1. Apply rule-based routing logic
2. Enhance classification with AI if configured
3. Check for duplicates
4. Create or update issues in target repositories
5. Add issues to GitHub Projects v2
6. Close the router issue with a link to the target

### Programmatic Usage

```typescript
import { quickRoute } from '@delax/routing-system';

const result = await quickRoute(issueData, {
  configPath: './config/routing.yml',
  githubToken: process.env.GITHUB_TOKEN,
  openaiApiKey: process.env.OPENAI_API_KEY,
  routerRepo: 'your-org/router',
  dryRun: false,
});

console.log('Routing result:', result);
```

### Advanced Configuration

#### Rule-Based Routing

Define complex routing rules using multiple criteria:

```yaml
rules:
  - when:
      channels: ["#backend", "#api"]
      keywords: ["API", "Supabase", "PostgreSQL"]
      titlePatterns: [".*API.*", ".*Backend.*"]
      bodyPatterns: ["authentication", "database"]
      labels: ["backend"]
    route:
      repo: "your-org/backend-services"
      labels: ["api", "backend"]
      assignees: ["backend-team"]
      priority: "medium"
      projectFields:
        Status: "Todo"
        Type: "Backend"
```

#### AI Classification

Configure the AI model for enhanced classification:

```yaml
llm:
  model: "claude-3-sonnet"
  maxTokens: 4000
  temperature: 0.1
```

#### Duplicate Detection

Configure duplicate detection strategies:

```yaml
duplicateDetection:
  enabled: true
  method: "both"  # "slack-permalink", "content-hash", or "both"
  lookbackDays: 30
```

## API Reference

### Core Classes

#### `IssueRouter`
Main routing orchestration class.

```typescript
const router = new IssueRouter({
  config: routingConfig,
  issue: issueData,
  gitHubToken: token,
  openAIApiKey: apiKey,
});

const result = await router.routeIssue(issue, routerRepo);
```

#### `IssueClassifier`
AI-powered issue classification.

```typescript
const classifier = new IssueClassifier(config, apiKey);
const classification = await classifier.classify(context);
```

#### `GitHubApiClient`
GitHub API operations for issue management.

```typescript
const client = new GitHubApiClient(token, config);
const result = await client.createIssue(classification, sourceIssue);
```

#### `ProjectsApiClient`
GitHub Projects v2 API operations.

```typescript
const projectsClient = new ProjectsApiClient(token);
await projectsClient.addIssueToProject(projectId, issueId, classification);
```

### Configuration Management

#### `ConfigManager`
Centralized configuration management.

```typescript
const manager = ConfigManager.getInstance();
const config = manager.getConfigWithEnvironment('production');
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GITHUB_TOKEN` | GitHub token for API access | Yes |
| `OPENAI_API_KEY` | OpenAI API key for AI classification | No |
| `ROUTING_CONFIG_PATH` | Path to routing configuration file | No |
| `DEFAULT_REPO` | Override for default repository | No |
| `DEFAULT_PROJECT_ORG` | Default project organization | No |
| `DEFAULT_PROJECT_NUMBER` | Default project number | No |
| `LLM_MODEL` | Override for AI model | No |
| `LLM_MAX_TOKENS` | Override for max tokens | No |
| `DUPLICATE_DETECTION_ENABLED` | Enable/disable duplicate detection | No |

## Troubleshooting

### Common Issues

1. **Configuration Validation Errors**
   ```bash
   npm run validate-config
   ```

2. **GitHub API Rate Limits**
   - Use a GitHub App token instead of personal access token
   - Implement request throttling

3. **AI Classification Failures**
   - Check OpenAI API key and quota
   - System falls back to rule-based routing

4. **Project Access Issues**
   - Verify token has project permissions
   - Check organization and project number

### Debug Mode

Enable verbose logging:

```typescript
const result = await quickRoute(issueData, {
  // ... other options
  verbose: true,
});
```

### Dry Run Mode

Test routing without making changes:

```typescript
const result = await quickRoute(issueData, {
  // ... other options
  dryRun: true,
});
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite: `npm test`
6. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

- [Documentation](./docs/)
- [Issue Tracker](https://github.com/your-org/routing-system/issues)
- [Discussions](https://github.com/your-org/routing-system/discussions)

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for release history.