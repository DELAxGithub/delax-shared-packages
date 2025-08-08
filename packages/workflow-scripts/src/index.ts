/**
 * @delax/workflow-scripts
 * 
 * High-efficiency development workflow automation for DELAX projects
 */

export interface DelaxConfig {
  project: {
    name: string;
    type: 'ios-swift' | 'react-typescript' | 'pm-web' | 'flutter' | 'generic';
  };
  git: {
    main_branch: string;
    remote_name: string;
  };
  notifications: {
    slack?: {
      webhook_url: string;
    };
    email?: {
      recipient: string;
    };
    macos?: {
      enabled: boolean;
    };
  };
}

export type NotificationType = 
  | 'pr-created'
  | 'build-success' 
  | 'build-failure'
  | 'ready-to-merge'
  | 'issue-fixed'
  | 'merge-completed'
  | 'merge-pulled'
  | 'build-recommended';

export interface WorkflowScripts {
  quickPull: () => Promise<void>;
  notify: (type: NotificationType, target?: string) => Promise<void>;
  syncPr: (prNumber: number) => Promise<void>;
  autoPull: (options?: { interval?: number }) => Promise<void>;
}

/**
 * Default configuration values
 */
export const DEFAULT_CONFIG: Partial<DelaxConfig> = {
  git: {
    main_branch: 'main',
    remote_name: 'origin',
  },
  notifications: {
    macos: {
      enabled: true,
    },
  },
};

/**
 * Get build command for project type
 */
export function getBuildCommand(projectType: DelaxConfig['project']['type']): string {
  switch (projectType) {
    case 'ios-swift':
      return './build.sh または Xcodeで⌘+B';
    case 'react-typescript':
    case 'pm-web':
      return 'pnpm run build または pnpm dev';
    case 'flutter':
      return 'flutter build または flutter run';
    default:
      return 'プロジェクト固有のビルドコマンド';
  }
}

/**
 * Get next steps for project type
 */
export function getNextSteps(projectType: DelaxConfig['project']['type']): string[] {
  switch (projectType) {
    case 'ios-swift':
      return [
        'Open Xcode',
        'Build the project (⌘+B)',
        'Test on simulator or device',
      ];
    case 'react-typescript':
    case 'pm-web':
      return [
        'Run: pnpm install',
        'Run: pnpm dev',
        'Test in browser',
      ];
    case 'flutter':
      return [
        'Run: flutter pub get',
        'Run: flutter run',
        'Test on simulator or device',
      ];
    default:
      return [
        'Run project-specific build command',
        'Test the changes',
        'Verify functionality',
      ];
  }
}

/**
 * Load configuration from file or environment
 */
export async function loadConfig(configPath?: string): Promise<DelaxConfig> {
  // This would be implemented to load from YAML file or environment variables
  // For now, return a default configuration
  const projectName = process.env.DELAX_PROJECT_NAME || process.cwd().split('/').pop() || 'unknown';
  const projectType = (process.env.DELAX_PROJECT_TYPE as DelaxConfig['project']['type']) || 'generic';
  
  return {
    project: {
      name: projectName,
      type: projectType,
    },
    git: {
      main_branch: process.env.DELAX_MAIN_BRANCH || 'main',
      remote_name: process.env.DELAX_REMOTE_NAME || 'origin',
    },
    notifications: {
      slack: process.env.SLACK_WEBHOOK_URL ? {
        webhook_url: process.env.SLACK_WEBHOOK_URL,
      } : undefined,
      email: process.env.NOTIFICATION_EMAIL ? {
        recipient: process.env.NOTIFICATION_EMAIL,
      } : undefined,
      macos: {
        enabled: true,
      },
    },
  };
}

// Re-export types for convenience
export type { DelaxConfig as Config };
export type { NotificationType };

/**
 * Version information
 */
export const VERSION = '1.0.0';
export const DESCRIPTION = 'High-efficiency development workflow automation for DELAX projects';