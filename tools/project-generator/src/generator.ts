import * as fs from 'fs-extra';
import * as path from 'path';
import Mustache from 'mustache';
import chalk from 'chalk';
import { ProjectTemplate, ProjectConfig, GeneratorOptions, TemplateFile } from './types';
import { execSync } from 'child_process';
import YAML from 'yaml';

export async function createProject(
  template: ProjectTemplate,
  config: ProjectConfig,
  options: GeneratorOptions
): Promise<void> {
  const projectPath = path.join(options.directory, config.projectName);
  
  // Create project directory
  await fs.ensureDir(projectPath);
  
  // Get template files
  const templateFiles = getTemplateFiles(template);
  const templateDir = path.join(__dirname, '..', 'templates', template);
  
  // Copy and process template files
  for (const file of templateFiles) {
    const sourcePath = path.join(templateDir, file.source);
    const destPath = path.join(projectPath, file.destination);
    
    await fs.ensureDir(path.dirname(destPath));
    
    if (file.isTemplate && await fs.pathExists(sourcePath)) {
      // Process template file with Mustache
      const templateContent = await fs.readFile(sourcePath, 'utf-8');
      const processedContent = Mustache.render(templateContent, getTemplateVariables(config));
      await fs.writeFile(destPath, processedContent);
    } else if (await fs.pathExists(sourcePath)) {
      // Copy file as-is
      await fs.copy(sourcePath, destPath);
    }
  }
  
  // Create delax-config.yml
  await createDelaxConfig(projectPath, config);
  
  // Copy workflow scripts from shared package
  await copyWorkflowScripts(projectPath);
  
  // Initialize git repository
  if (!options.skipGit) {
    await initializeGit(projectPath);
  }
  
  // Install dependencies
  if (!options.skipInstall) {
    await installDependencies(projectPath, template);
  }
  
  console.log(chalk.green(`✅ Project created at: ${projectPath}`));
}

function getTemplateFiles(template: ProjectTemplate): TemplateFile[] {
  const commonFiles: TemplateFile[] = [
    { source: 'README.md.mustache', destination: 'README.md', isTemplate: true },
    { source: 'gitignore', destination: '.gitignore' },
    { source: '.github/workflows/claude.yml', destination: '.github/workflows/claude.yml' },
  ];
  
  switch (template) {
    case 'ios-swift':
      return [
        ...commonFiles,
        { source: 'project.xcodeproj', destination: `{{projectName}}.xcodeproj` },
        { source: 'build.sh.mustache', destination: 'build.sh', isTemplate: true },
        { source: '.github/workflows/ios-code-check.yml', destination: '.github/workflows/ios-code-check.yml' },
        { source: 'src/App.swift.mustache', destination: `{{projectName}}/App.swift`, isTemplate: true },
        { source: 'src/ContentView.swift.mustache', destination: `{{projectName}}/ContentView.swift`, isTemplate: true },
      ];
      
    case 'pm-web':
      return [
        ...commonFiles,
        { source: 'package.json.mustache', destination: 'package.json', isTemplate: true },
        { source: 'pnpm-workspace.yaml', destination: 'pnpm-workspace.yaml' },
        { source: 'turbo.json', destination: 'turbo.json' },
        { source: '.github/workflows/pm-code-check.yml', destination: '.github/workflows/pm-code-check.yml' },
        { source: 'apps/unified/package.json.mustache', destination: 'apps/unified/package.json', isTemplate: true },
        { source: 'apps/unified/next.config.js', destination: 'apps/unified/next.config.js' },
        { source: 'supabase/config.toml.mustache', destination: 'supabase/config.toml', isTemplate: true },
      ];
      
    case 'flutter':
      return [
        ...commonFiles,
        { source: 'pubspec.yaml.mustache', destination: 'pubspec.yaml', isTemplate: true },
        { source: 'lib/main.dart.mustache', destination: 'lib/main.dart', isTemplate: true },
        { source: 'lib/app.dart.mustache', destination: 'lib/app.dart', isTemplate: true },
        { source: '.github/workflows/flutter-code-check.yml', destination: '.github/workflows/flutter-code-check.yml' },
      ];
      
    default:
      return commonFiles;
  }
}

function getTemplateVariables(config: ProjectConfig): Record<string, any> {
  return {
    projectName: config.projectName,
    description: config.description,
    author: config.author,
    bundleId: config.bundleId,
    supabaseUrl: config.supabaseUrl,
    enableClaudeKit: config.enableClaudeKit,
    enableSwiftData: config.enableSwiftData,
    enableHealthKit: config.enableHealthKit,
    enableRealtime: config.enableRealtime,
    enableAuth: config.enableAuth,
    enableSupabase: config.enableSupabase,
    enableRiverpod: config.enableRiverpod,
    deploymentPlatform: config.deploymentPlatform,
    targetPlatforms: config.targetPlatforms,
    slackWebhook: config.slackWebhook,
    notificationEmail: config.notificationEmail,
    year: new Date().getFullYear(),
  };
}

async function createDelaxConfig(projectPath: string, config: ProjectConfig): Promise<void> {
  const delaxConfig = {
    project: {
      name: config.projectName,
      type: config.template,
      description: config.description,
    },
    git: {
      main_branch: 'main',
      remote_name: 'origin',
    },
    notifications: {
      ...(config.enableSlackNotifications && config.slackWebhook && {
        slack: {
          webhook_url: config.slackWebhook,
        },
      }),
      ...(config.enableEmailNotifications && config.notificationEmail && {
        email: {
          recipient: config.notificationEmail,
        },
      }),
      macos: {
        enabled: true,
      },
    },
    ...(config.template === 'ios-swift' && {
      ios: {
        bundle_id: config.bundleId,
        features: {
          claudekit: config.enableClaudeKit,
          swiftdata: config.enableSwiftData,
          healthkit: config.enableHealthKit,
        },
      },
    }),
    ...(config.template === 'pm-web' && {
      web: {
        supabase_url: config.supabaseUrl,
        features: {
          realtime: config.enableRealtime,
          auth: config.enableAuth,
        },
        deployment: {
          platform: config.deploymentPlatform,
        },
      },
    }),
    ...(config.template === 'flutter' && {
      flutter: {
        features: {
          supabase: config.enableSupabase,
          riverpod: config.enableRiverpod,
        },
        platforms: config.targetPlatforms,
      },
    }),
  };
  
  const configPath = path.join(projectPath, 'delax-config.yml');
  await fs.writeFile(configPath, YAML.stringify(delaxConfig));
}

async function copyWorkflowScripts(projectPath: string): Promise<void> {
  const scriptsDir = path.join(projectPath, 'scripts');
  await fs.ensureDir(scriptsDir);
  
  // In a real implementation, this would copy from the workflow-scripts package
  // For now, we'll create placeholder files
  const scripts = ['quick-pull.sh', 'notify.sh', 'sync-pr.sh', 'auto-pull.sh'];
  
  for (const script of scripts) {
    const scriptPath = path.join(scriptsDir, script);
    await fs.writeFile(scriptPath, `#!/bin/bash\n\n# Placeholder for ${script}\n# Install @delax/workflow-scripts for full functionality\n\necho "Please install @delax/workflow-scripts package"\necho "npm install -g @delax/workflow-scripts"\necho "Then use: delax-${script.replace('.sh', '').replace('-', '-')}"\n`);
    await fs.chmod(scriptPath, '755');
  }
}

async function initializeGit(projectPath: string): Promise<void> {
  try {
    execSync('git init', { cwd: projectPath, stdio: 'ignore' });
    execSync('git add .', { cwd: projectPath, stdio: 'ignore' });
    execSync('git commit -m "🎉 Initial commit with DELAX technical heritage\\n\\n🤖 Generated with @delax/project-generator\\n\\nCo-authored-by: Claude <noreply@anthropic.com>"', { 
      cwd: projectPath, 
      stdio: 'ignore' 
    });
    console.log(chalk.green('✅ Git repository initialized'));
  } catch (error) {
    console.warn(chalk.yellow('⚠️ Git initialization failed'));
  }
}

async function installDependencies(projectPath: string, template: ProjectTemplate): Promise<void> {
  try {
    switch (template) {
      case 'pm-web':
        console.log(chalk.blue('📦 Installing pnpm dependencies...'));
        execSync('pnpm install', { cwd: projectPath, stdio: 'inherit' });
        break;
        
      case 'flutter':
        console.log(chalk.blue('📦 Installing Flutter dependencies...'));
        execSync('flutter pub get', { cwd: projectPath, stdio: 'inherit' });
        break;
        
      case 'ios-swift':
        console.log(chalk.blue('📦 iOS project ready (no package manager installation needed)'));
        break;
        
      default:
        console.log(chalk.blue('📦 Generic project created (no automatic dependency installation)'));
    }
  } catch (error) {
    console.warn(chalk.yellow('⚠️ Dependency installation failed - you may need to install manually'));
  }
}