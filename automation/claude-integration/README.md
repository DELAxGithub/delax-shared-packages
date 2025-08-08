# 🤖 Claude Integration Library

Universal Claude AI integration library for development automation. Power your development tools with Claude 4 Sonnet's advanced reasoning capabilities.

![Claude](https://img.shields.io/badge/Claude-4%20Sonnet-purple)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0%2B-blue)
![Node.js](https://img.shields.io/badge/Node.js-18%2B-green)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- 🧠 **Multi-Language Support**: Swift, TypeScript, Python, JavaScript
- 🎯 **Context-Aware**: Project-specific prompt generation
- 🔧 **Structured Output**: Parsed fixes with confidence scores
- 📝 **Template System**: Customizable prompt templates
- 🚀 **Easy Integration**: Simple API for any development tool
- 🛡️ **Type Safe**: Full TypeScript support

## 🚀 Quick Start

### Installation

```bash
npm install @delax/claude-integration
```

### Basic Usage

```typescript
import { ClaudeIntegration, ErrorContext } from '@delax/claude-integration';

const claude = new ClaudeIntegration({
  model: 'claude-4-sonnet-20250514',
  apiKey: process.env.ANTHROPIC_API_KEY
});

const context: ErrorContext = {
  language: 'swift',
  framework: 'SwiftUI',
  errorType: 'SWIFT_ERROR',
  errorMessage: 'Cannot find \'ContentView\' in scope',
  filePath: 'App.swift',
  lineNumber: 15,
  projectContext: {
    name: 'MyApp',
    architecture: 'SwiftUI + MVVM',
    patterns: ['@State', '@StateObject', '@ObservedObject']
  }
};

const response = await claude.generateFix(context);

if (response.success) {
  console.log('Analysis:', response.analysis);
  response.suggestions.forEach(fix => {
    console.log(`Fix (${fix.confidence * 100}% confidence):`, fix.content);
    console.log('Explanation:', fix.explanation);
  });
}
```

## 📖 API Reference

### ClaudeIntegration

#### Constructor
```typescript
new ClaudeIntegration(config: ClaudeConfig)
```

#### Methods
- `generateFix(context: ErrorContext): Promise<ClaudeResponse>`

### Types

#### ClaudeConfig
```typescript
interface ClaudeConfig {
  model: string;
  apiKey?: string;
  maxTokens?: number;
  temperature?: number;
}
```

#### ErrorContext
```typescript
interface ErrorContext {
  language: 'swift' | 'typescript' | 'python' | 'javascript';
  framework?: string;
  errorType: string;
  errorMessage: string;
  filePath?: string;
  lineNumber?: number;
  projectContext?: ProjectContext;
}
```

#### ClaudeResponse
```typescript
interface ClaudeResponse {
  success: boolean;
  suggestions: FixSuggestion[];
  analysis: string;
  error?: string;
}
```

## 🎯 Language Support

### Swift/iOS
```typescript
const context: ErrorContext = {
  language: 'swift',
  framework: 'SwiftUI',
  errorType: 'SWIFT_ERROR',
  errorMessage: 'Type mismatch error',
  projectContext: {
    architecture: 'SwiftUI + SwiftData + MVVM',
    patterns: ['@Model', '@Query', '@State']
  }
};
```

### TypeScript/React
```typescript
const context: ErrorContext = {
  language: 'typescript',
  framework: 'React',
  errorType: 'TYPE_ERROR',
  errorMessage: 'Property does not exist on type',
  projectContext: {
    architecture: 'React + TypeScript + Hooks',
    dependencies: ['react', '@types/react']
  }
};
```

### Python
```typescript
const context: ErrorContext = {
  language: 'python',
  framework: 'Django',
  errorType: 'IMPORT_ERROR',
  errorMessage: 'No module named django.core',
  projectContext: {
    architecture: 'Django + REST Framework',
    dependencies: ['django', 'djangorestframework']
  }
};
```

## 🔧 Advanced Usage

### Custom Templates

```typescript
// Extend for custom prompt templates
class CustomClaudeIntegration extends ClaudeIntegration {
  protected getCustomTemplate(): string {
    return `
      Custom prompt template for specific use cases...
      Context: {{projectContext}}
      Error: {{errorMessage}}
    `;
  }
}
```

### Batch Processing

```typescript
const errors: ErrorContext[] = [
  // Multiple error contexts
];

const results = await Promise.all(
  errors.map(error => claude.generateFix(error))
);
```

### Configuration Options

```typescript
const claude = new ClaudeIntegration({
  model: 'claude-4-sonnet-20250514',
  apiKey: process.env.ANTHROPIC_API_KEY,
  maxTokens: 4000,
  temperature: 0.1  // Lower for more deterministic fixes
});
```

## 🏗️ Integration Examples

### iOS Auto-Fix Integration
```typescript
// Used by @delax/ios-auto-fix
import { ClaudeIntegration } from '@delax/claude-integration';

export class iOSAutoFix {
  private claude: ClaudeIntegration;
  
  constructor() {
    this.claude = new ClaudeIntegration({
      model: 'claude-4-sonnet-20250514'
    });
  }
  
  async fixXcodeErrors(errors: XcodeError[]): Promise<FixResult[]> {
    return Promise.all(errors.map(async (error) => {
      const context: ErrorContext = {
        language: 'swift',
        errorType: error.type,
        errorMessage: error.message,
        filePath: error.file,
        lineNumber: error.line
      };
      
      return await this.claude.generateFix(context);
    }));
  }
}
```

### Web Development Integration
```typescript
// Integration with build tools
import { ClaudeIntegration } from '@delax/claude-integration';

export class WebAutoFix {
  private claude: ClaudeIntegration;
  
  async fixTypeScriptErrors(tscOutput: string): Promise<FixResult[]> {
    const errors = this.parseTscOutput(tscOutput);
    
    return Promise.all(errors.map(async (error) => {
      const context: ErrorContext = {
        language: 'typescript',
        errorType: 'TYPE_ERROR',
        errorMessage: error.message,
        filePath: error.file,
        projectContext: {
          name: 'WebApp',
          architecture: 'React + TypeScript + Vite'
        }
      };
      
      return await this.claude.generateFix(context);
    }));
  }
}
```

## 🛡️ Error Handling

```typescript
try {
  const response = await claude.generateFix(context);
  
  if (!response.success) {
    console.error('Claude integration failed:', response.error);
    return;
  }
  
  // Process successful response
  for (const suggestion of response.suggestions) {
    if (suggestion.confidence > 0.8) {
      // Apply high-confidence fixes automatically
      await applyFix(suggestion);
    } else {
      // Present low-confidence fixes for review
      await presentForReview(suggestion);
    }
  }
} catch (error) {
  console.error('Unexpected error:', error);
}
```

## 🔍 Best Practices

1. **Provide Rich Context**: More context leads to better fixes
2. **Check Confidence Scores**: Only auto-apply high-confidence fixes
3. **Handle Failures Gracefully**: Always have fallback strategies
4. **Rate Limiting**: Respect API limits in batch operations
5. **Template Customization**: Tailor prompts for your specific use cases

## 🤝 Contributing

We welcome contributions! This library is part of the [DELAX Shared Packages](https://github.com/DELAxGithub/delax-shared-packages) ecosystem.

### Development Setup
```bash
git clone https://github.com/DELAxGithub/delax-shared-packages.git
cd delax-shared-packages/ai-automation/claude-integration
npm install
npm run dev
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Power your development tools with Claude 4 Sonnet!** 🤖✨

> Part of the [DELAX Shared Packages](https://github.com/DELAxGithub/delax-shared-packages) ecosystem