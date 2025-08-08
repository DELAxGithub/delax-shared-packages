/**
 * Tests for the routing system
 */

import { IssueRouter } from '../src/router';
import { createTestConfig } from '../src/config';
import type { IssueData, RouterContext } from '../src/types';

describe('Issue Routing System', () => {
  let router: IssueRouter;
  let mockContext: RouterContext;
  let mockIssue: IssueData;

  beforeEach(() => {
    mockIssue = {
      title: 'Test iOS SwiftUI issue',
      body: 'Having trouble with CloudKit sync in SwiftUI',
      number: 1,
      url: 'https://github.com/test-org/router/issues/1',
      author: 'test-user',
      labels: ['bug'],
      assignees: [],
      createdAt: '2024-01-01T00:00:00Z',
      slackPermalink: null,
      sourceMeta: {
        channel: '#ios-dev',
        repository: 'router',
      },
    };

    mockContext = {
      config: createTestConfig({
        defaults: {
          repo: 'test-org/inbox',
          labels: ['triage'],
        },
        rules: [
          {
            when: {
              keywords: ['iOS', 'SwiftUI', 'CloudKit'],
              channels: ['#ios-dev'],
            },
            route: {
              repo: 'test-org/ios-app',
              labels: ['ios', 'mobile'],
              priority: 'high',
            },
          },
          {
            when: {
              keywords: ['backend', 'API'],
            },
            route: {
              repo: 'test-org/backend',
              labels: ['backend'],
              priority: 'medium',
            },
          },
        ],
      }),
      issue: mockIssue,
      gitHubToken: 'mock-token',
      dryRun: true,
      verbose: false,
    };

    router = new IssueRouter(mockContext);
  });

  describe('Rule-based routing', () => {
    test('should route iOS issues correctly', async () => {
      const result = await router.routeIssue(mockIssue, 'test-org/router');

      expect(result.success).toBe(true);
      expect(result.classification.repo).toBe('test-org/ios-app');
      expect(result.classification.labels).toContain('ios');
      expect(result.classification.labels).toContain('mobile');
      expect(result.classification.priority).toBe('high');
      expect(result.classification.confidence).toBeGreaterThan(0.9);
    });

    test('should route backend issues correctly', async () => {
      mockIssue.title = 'API authentication issue';
      mockIssue.body = 'Backend API is returning 401 errors';
      mockContext.issue = mockIssue;

      const router = new IssueRouter(mockContext);
      const result = await router.routeIssue(mockIssue, 'test-org/router');

      expect(result.success).toBe(true);
      expect(result.classification.repo).toBe('test-org/backend');
      expect(result.classification.labels).toContain('backend');
      expect(result.classification.priority).toBe('medium');
    });

    test('should fallback to default repo when no rules match', async () => {
      mockIssue.title = 'Random unmatched issue';
      mockIssue.body = 'This should not match any rules';
      mockContext.issue = mockIssue;

      const router = new IssueRouter(mockContext);
      const result = await router.routeIssue(mockIssue, 'test-org/router');

      expect(result.success).toBe(true);
      expect(result.classification.repo).toBe('test-org/inbox');
      expect(result.classification.confidence).toBeLessThan(0.5);
    });
  });

  describe('Duplicate detection', () => {
    test('should detect duplicate by Slack permalink', async () => {
      mockIssue.slackPermalink = 'https://test.slack.com/archives/C123/p1234567890';
      mockContext.issue = mockIssue;

      // Mock the GitHub API to return a duplicate
      const router = new IssueRouter(mockContext);
      const result = await router.routeIssue(mockIssue, 'test-org/router');

      // In dry run mode, it should still process but not create actual issues
      expect(result.classification).toBeDefined();
      expect(result.duplicateCheck).toBeDefined();
    });

    test('should handle content hash duplicate detection', async () => {
      const router = new IssueRouter(mockContext);
      const result = await router.routeIssue(mockIssue, 'test-org/router');

      // Verify that content hash is generated for duplicate detection
      expect(result.duplicateCheck).toBeDefined();
      expect(result.duplicateCheck.method).toBeDefined();
    });
  });

  describe('Configuration validation', () => {
    test('should validate valid configuration', () => {
      const validation = IssueRouter.validateConfig(mockContext.config);
      expect(validation.valid).toBe(true);
      expect(validation.errors).toHaveLength(0);
    });

    test('should reject invalid configuration', () => {
      const invalidConfig = {
        defaults: {
          // Missing repo
          labels: [],
        },
        rules: [], // Empty rules
      };

      const validation = IssueRouter.validateConfig(invalidConfig as any);
      expect(validation.valid).toBe(false);
      expect(validation.errors.length).toBeGreaterThan(0);
    });
  });

  describe('Error handling', () => {
    test('should handle GitHub API errors gracefully', async () => {
      // Mock a failing context
      const failingContext = {
        ...mockContext,
        gitHubToken: 'invalid-token',
      };

      const router = new IssueRouter(failingContext);
      const result = await router.routeIssue(mockIssue, 'test-org/router');

      // Should not crash but should indicate failure
      expect(result).toBeDefined();
      expect(result.logs).toBeDefined();
      expect(result.executionTime).toBeGreaterThan(0);
    });

    test('should handle missing configuration gracefully', async () => {
      const emptyConfig = createTestConfig({
        defaults: { repo: 'test-org/fallback', labels: [] },
        rules: [],
      });

      const contextWithEmptyConfig = {
        ...mockContext,
        config: emptyConfig,
      };

      const router = new IssueRouter(contextWithEmptyConfig);
      const result = await router.routeIssue(mockIssue, 'test-org/router');

      // Should fallback to default repo
      expect(result.classification.repo).toBe('test-org/fallback');
    });
  });

  describe('Performance', () => {
    test('should complete routing within reasonable time', async () => {
      const startTime = Date.now();
      const result = await router.routeIssue(mockIssue, 'test-org/router');
      const endTime = Date.now();

      expect(endTime - startTime).toBeLessThan(5000); // Should complete in under 5 seconds
      expect(result.executionTime).toBeLessThan(5000);
    });

    test('should handle multiple concurrent routing requests', async () => {
      const promises = Array.from({ length: 5 }, (_, i) => {
        const testIssue = {
          ...mockIssue,
          number: i + 1,
          title: `Test issue ${i + 1}`,
        };
        return router.routeIssue(testIssue, 'test-org/router');
      });

      const results = await Promise.all(promises);

      expect(results).toHaveLength(5);
      results.forEach(result => {
        expect(result.classification).toBeDefined();
        expect(result.executionTime).toBeGreaterThan(0);
      });
    });
  });
});