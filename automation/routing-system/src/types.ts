/**
 * Core types for the routing system
 */

import { z } from 'zod';

// GitHub Issue related types
export interface IssueData {
  title: string;
  body: string;
  number: number;
  url: string;
  author: string;
  labels: string[];
  assignees: string[];
  createdAt: string;
  slackPermalink?: string;
  sourceMeta?: Record<string, unknown>;
}

// Routing classification result
export interface ClassificationResult {
  repo: string;
  title: string;
  body: string;
  labels: string[];
  assignees: string[];
  priority: 'low' | 'medium' | 'high' | 'critical';
  confidence: number;
  reasoning: string;
  projectFields?: Record<string, string | number>;
}

// Rule-based routing
export const RoutingRuleSchema = z.object({
  when: z.object({
    channels: z.array(z.string()).optional(),
    keywords: z.array(z.string()).optional(),
    labels: z.array(z.string()).optional(),
    titlePatterns: z.array(z.string()).optional(),
    bodyPatterns: z.array(z.string()).optional(),
  }),
  route: z.object({
    repo: z.string(),
    labels: z.array(z.string()).optional(),
    assignees: z.array(z.string()).optional(),
    priority: z.enum(['low', 'medium', 'high', 'critical']).optional(),
    projectFields: z.record(z.union([z.string(), z.number()])).optional(),
  }),
});

export type RoutingRule = z.infer<typeof RoutingRuleSchema>;

// Configuration schema
export const RoutingConfigSchema = z.object({
  defaults: z.object({
    repo: z.string(),
    labels: z.array(z.string()).default([]),
    project: z.object({
      org: z.string(),
      number: z.number(),
    }).optional(),
  }),
  rules: z.array(RoutingRuleSchema),
  llm: z.object({
    model: z.string().default('claude-3-sonnet'),
    maxTokens: z.number().default(4000),
    temperature: z.number().default(0.1),
  }).optional(),
  duplicateDetection: z.object({
    enabled: z.boolean().default(true),
    method: z.enum(['slack-permalink', 'content-hash', 'both']).default('both'),
    lookbackDays: z.number().default(30),
  }).optional(),
});

export type RoutingConfig = z.infer<typeof RoutingConfigSchema>;

// GitHub Projects v2 related types
export interface ProjectField {
  id: string;
  name: string;
  dataType: 'TEXT' | 'NUMBER' | 'DATE' | 'SINGLE_SELECT' | 'ITERATION';
  options?: ProjectFieldOption[];
}

export interface ProjectFieldOption {
  id: string;
  name: string;
}

export interface ProjectInfo {
  id: string;
  number: number;
  title: string;
  url: string;
  fields: ProjectField[];
}

// GitHub API operation result
export interface GitHubOperationResult {
  success: boolean;
  issueNumber?: number;
  issueUrl?: string;
  projectItemId?: string;
  error?: string;
  details?: Record<string, unknown>;
}

// Duplicate detection result
export interface DuplicateCheckResult {
  isDuplicate: boolean;
  existingIssue?: {
    number: number;
    url: string;
    repo: string;
  };
  method: 'slack-permalink' | 'content-hash' | 'none';
  confidence: number;
}

// LLM Classification context
export interface ClassificationContext {
  issue: IssueData;
  availableRepos: string[];
  existingLabels: Record<string, string[]>; // repo -> labels
  historicalClassifications?: ClassificationResult[];
  organizationContext?: string;
}

// Router execution context
export interface RouterContext {
  config: RoutingConfig;
  issue: IssueData;
  gitHubToken: string;
  openAIApiKey?: string;
  dryRun?: boolean;
  verbose?: boolean;
}

// Routing execution result
export interface RoutingResult {
  success: boolean;
  classification: ClassificationResult;
  duplicateCheck: DuplicateCheckResult;
  githubOperation: GitHubOperationResult;
  executionTime: number;
  logs: string[];
  error?: string;
}

// Export validation schemas
export const IssueDataSchema = z.object({
  title: z.string(),
  body: z.string(),
  number: z.number(),
  url: z.string(),
  author: z.string(),
  labels: z.array(z.string()),
  assignees: z.array(z.string()),
  createdAt: z.string(),
  slackPermalink: z.string().optional(),
  sourceMeta: z.record(z.unknown()).optional(),
});

export const ClassificationResultSchema = z.object({
  repo: z.string(),
  title: z.string(),
  body: z.string(),
  labels: z.array(z.string()),
  assignees: z.array(z.string()),
  priority: z.enum(['low', 'medium', 'high', 'critical']),
  confidence: z.number().min(0).max(1),
  reasoning: z.string(),
  projectFields: z.record(z.union([z.string(), z.number()])).optional(),
});

// Configuration validation helpers
export function validateRoutingConfig(config: unknown): RoutingConfig {
  return RoutingConfigSchema.parse(config);
}

export function validateIssueData(data: unknown): IssueData {
  return IssueDataSchema.parse(data);
}

export function validateClassificationResult(result: unknown): ClassificationResult {
  return ClassificationResultSchema.parse(result);
}