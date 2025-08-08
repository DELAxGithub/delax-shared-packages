/**
 * Claude Integration Library
 * Universal Claude AI integration for development automation
 */

export interface ClaudeConfig {
  model: string;
  apiKey?: string;
  maxTokens?: number;
  temperature?: number;
}

export interface ErrorContext {
  language: 'swift' | 'typescript' | 'python' | 'javascript' | 'dart';
  framework?: string;
  errorType: string;
  errorMessage: string;
  filePath?: string;
  lineNumber?: number;
  projectContext?: ProjectContext;
}

export interface ProjectContext {
  name: string;
  description?: string;
  architecture?: string;
  dependencies?: string[];
  patterns?: string[];
}

export interface FixSuggestion {
  type: 'patch' | 'code' | 'command' | 'config';
  content: string;
  explanation: string;
  confidence: number;
  filePath?: string;
}

export interface ClaudeResponse {
  success: boolean;
  suggestions: FixSuggestion[];
  analysis: string;
  error?: string;
}

/**
 * Core Claude Integration Class
 */
export class ClaudeIntegration {
  private config: ClaudeConfig;

  constructor(config: ClaudeConfig) {
    this.config = config;
  }

  /**
   * Analyze errors and generate fixes
   */
  async generateFix(context: ErrorContext): Promise<ClaudeResponse> {
    try {
      const prompt = this.buildPrompt(context);
      const response = await this.callClaude(prompt);
      return this.parseResponse(response);
    } catch (error) {
      return {
        success: false,
        suggestions: [],
        analysis: '',
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Build context-aware prompt for Claude
   */
  private buildPrompt(context: ErrorContext): string {
    const templates = {
      swift: this.getSwiftTemplate(),
      typescript: this.getTypeScriptTemplate(),
      python: this.getPythonTemplate(),
      javascript: this.getJavaScriptTemplate(),
      dart: this.getDartTemplate()
    };

    const template = templates[context.language];
    return this.interpolateTemplate(template, context);
  }

  /**
   * Call Claude API
   */
  private async callClaude(prompt: string): Promise<string> {
    // Implementation would use @anthropic-ai/sdk or claude-cli
    // For now, return mock response
    return `
## Analysis
The error appears to be a ${this.config.model} analysis...

## Fix Suggestion
\`\`\`diff
- // old code
+ // new code
\`\`\`

## Explanation
This fix addresses the root cause by...
    `;
  }

  /**
   * Parse Claude's response into structured format
   */
  private parseResponse(response: string): ClaudeResponse {
    // Parse the response and extract fixes
    const suggestions: FixSuggestion[] = [{
      type: 'patch',
      content: '// Generated fix content',
      explanation: 'Fix explanation',
      confidence: 0.85
    }];

    return {
      success: true,
      suggestions,
      analysis: 'Analysis from Claude',
    };
  }

  /**
   * Language-specific prompt templates
   */
  private getSwiftTemplate(): string {
    return `
You are Claude 4 Sonnet, an expert iOS developer.

Context: {{projectContext}}
Error Type: {{errorType}}
Error Message: {{errorMessage}}
File: {{filePath}}{{#lineNumber}} (Line {{lineNumber}}){{/lineNumber}}

Generate a precise fix that:
- Follows Swift best practices
- Maintains SwiftUI patterns
- Ensures iOS compatibility
- Provides minimal changes

Response format:
## Analysis
[Root cause analysis]

## Fix
\`\`\`diff
[Unified diff patch]
\`\`\`

## Explanation
[Why this fix works]
    `;
  }

  private getTypeScriptTemplate(): string {
    return `
You are Claude 4 Sonnet, an expert TypeScript developer.

Context: {{projectContext}}
Error Type: {{errorType}}
Error Message: {{errorMessage}}
File: {{filePath}}{{#lineNumber}} (Line {{lineNumber}}){{/lineNumber}}

Generate a precise TypeScript fix that:
- Maintains type safety
- Follows modern ES standards
- Ensures framework compatibility
- Provides minimal changes

Response format:
## Analysis
[Root cause analysis]

## Fix
\`\`\`diff
[Unified diff patch]
\`\`\`

## Explanation
[Why this fix works]
    `;
  }

  private getPythonTemplate(): string {
    return `
You are Claude 4 Sonnet, an expert Python developer.

Context: {{projectContext}}
Error Type: {{errorType}}
Error Message: {{errorMessage}}
File: {{filePath}}{{#lineNumber}} (Line {{lineNumber}}){{/lineNumber}}

Generate a precise Python fix that:
- Follows PEP standards
- Maintains compatibility
- Ensures proper imports
- Provides minimal changes

Response format:
## Analysis
[Root cause analysis]

## Fix
\`\`\`diff
[Unified diff patch]
\`\`\`

## Explanation
[Why this fix works]
    `;
  }

  private getJavaScriptTemplate(): string {
    return `
You are Claude 4 Sonnet, an expert JavaScript developer.

Context: {{projectContext}}
Error Type: {{errorType}}
Error Message: {{errorMessage}}
File: {{filePath}}{{#lineNumber}} (Line {{lineNumber}}){{/lineNumber}}

Generate a precise JavaScript fix that:
- Follows modern JS standards
- Maintains framework patterns
- Ensures browser compatibility
- Provides minimal changes

Response format:
## Analysis
[Root cause analysis]

## Fix
\`\`\`diff
[Unified diff patch]
\`\`\`

## Explanation
[Why this fix works]
    `;
  }

  private getDartTemplate(): string {
    return `
You are Claude 4 Sonnet, an expert Flutter/Dart developer.

Context: {{projectContext}}
Error Type: {{errorType}}
Error Message: {{errorMessage}}
File: {{filePath}}{{#lineNumber}} (Line {{lineNumber}}){{/lineNumber}}

Generate a precise Dart/Flutter fix that:
- Follows Dart style guidelines and conventions
- Maintains Flutter best practices and patterns
- Ensures null safety compliance
- Optimizes performance (const constructors, etc.)
- Removes deprecated API usage
- Provides minimal, surgical changes
- Maintains existing functionality

Common Flutter/Dart error patterns to fix:
- avoid_print: Replace print() with developer.log()
- prefer_const_constructors: Add const where beneficial
- avoid_redundant_argument_values: Remove default value arguments
- deprecated_member_use: Update to current API
- unused_local_variable: Remove or utilize variables
- prefer_single_quotes: Use single quotes for strings

Response format:
## Analysis
[Root cause analysis and fix strategy]

## Fix
\`\`\`diff
[Unified diff patch showing exact changes]
\`\`\`

## Explanation
[Why this fix works and maintains code quality]

## Flutter Context
[Any Flutter-specific considerations or side effects]
    `;
  }

  /**
   * Simple template interpolation
   */
  private interpolateTemplate(template: string, context: ErrorContext): string {
    return template
      .replace(/\{\{projectContext\}\}/g, JSON.stringify(context.projectContext))
      .replace(/\{\{errorType\}\}/g, context.errorType)
      .replace(/\{\{errorMessage\}\}/g, context.errorMessage)
      .replace(/\{\{filePath\}\}/g, context.filePath || '')
      .replace(/\{\{#lineNumber\}\}(.*?)\{\{\/lineNumber\}\}/g, 
        context.lineNumber ? `$1`.replace(/\{\{lineNumber\}\}/g, context.lineNumber.toString()) : '');
  }
}

/**
 * Factory function for easy instantiation
 */
export function createClaudeIntegration(config: ClaudeConfig): ClaudeIntegration {
  return new ClaudeIntegration(config);
}

/**
 * Default export
 */
export default ClaudeIntegration;