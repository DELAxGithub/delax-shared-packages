/**
 * Test setup file
 * This file is run before all tests
 */

// Mock environment variables
process.env.GITHUB_TOKEN = 'mock-github-token';
process.env.OPENAI_API_KEY = 'mock-openai-key';

// Mock console methods in tests to reduce noise
global.console = {
  ...console,
  // Uncomment to silence logs during tests
  // log: jest.fn(),
  // warn: jest.fn(),
  // error: jest.fn(),
};

// Global test utilities
global.mockIssueData = {
  title: 'Test Issue',
  body: 'This is a test issue body',
  number: 1,
  url: 'https://github.com/test-org/test-repo/issues/1',
  author: 'test-user',
  labels: ['test'],
  assignees: [],
  createdAt: new Date().toISOString(),
  slackPermalink: null,
  sourceMeta: {
    repository: 'test-repo',
    sender: 'test-user',
    action: 'opened',
  },
};

global.mockConfig = {
  defaults: {
    repo: 'test-org/inbox',
    labels: ['triage'],
  },
  rules: [
    {
      when: {
        keywords: ['test'],
      },
      route: {
        repo: 'test-org/test-repo',
        labels: ['test-label'],
      },
    },
  ],
};