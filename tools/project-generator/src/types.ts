export type ProjectTemplate = 'ios-swift' | 'pm-web' | 'flutter' | 'generic';

export interface ProjectConfig {
  projectName: string;
  template: ProjectTemplate;
  description?: string;
  author?: string;
  
  // iOS Swift specific
  bundleId?: string;
  enableClaudeKit?: boolean;
  enableSwiftData?: boolean;
  enableHealthKit?: boolean;
  
  // PM Web specific
  supabaseUrl?: string;
  enableRealtime?: boolean;
  enableAuth?: boolean;
  deploymentPlatform?: 'Netlify' | 'Vercel' | 'None';
  
  // Flutter specific
  enableSupabase?: boolean;
  enableRiverpod?: boolean;
  targetPlatforms?: string;
  
  // Common notification settings
  enableSlackNotifications?: boolean;
  slackWebhook?: string;
  enableEmailNotifications?: boolean;
  notificationEmail?: string;
}

export interface GeneratorOptions {
  directory: string;
  skipInstall?: boolean;
  skipGit?: boolean;
}

export interface TemplateFile {
  source: string;
  destination: string;
  isTemplate?: boolean;
}