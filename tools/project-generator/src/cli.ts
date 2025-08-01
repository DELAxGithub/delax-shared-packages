#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import inquirer from 'inquirer';
import { createProject } from './generator';
import { ProjectTemplate, ProjectConfig } from './types';

const program = new Command();

program
  .name('delax-create')
  .description('Create new DELAX projects with technical heritage')
  .version('1.0.0');

program
  .argument('<template>', 'Project template (ios-swift, pm-web, flutter, generic)')
  .argument('<name>', 'Project name')
  .option('-d, --directory <dir>', 'Output directory', '.')
  .option('--skip-install', 'Skip package installation')
  .option('--skip-git', 'Skip git initialization')
  .action(async (template: string, name: string, options) => {
    console.log(chalk.blue('🚀 DELAX Project Generator'));
    console.log('');

    // Validate template
    const validTemplates: ProjectTemplate[] = ['ios-swift', 'pm-web', 'flutter', 'generic'];
    if (!validTemplates.includes(template as ProjectTemplate)) {
      console.error(chalk.red(`❌ Invalid template: ${template}`));
      console.error(chalk.yellow(`Available templates: ${validTemplates.join(', ')}`));
      process.exit(1);
    }

    // Collect project configuration
    const config = await collectProjectConfig(template as ProjectTemplate, name);
    
    try {
      console.log(chalk.blue('📦 Creating project...'));
      await createProject(template as ProjectTemplate, config, options);
      
      console.log('');
      console.log(chalk.green('🎉 Project created successfully!'));
      console.log('');
      console.log(chalk.blue('📋 Next steps:'));
      console.log(chalk.yellow(`  cd ${config.projectName}`));
      
      switch (template) {
        case 'ios-swift':
          console.log(chalk.yellow('  open *.xcodeproj'));
          console.log(chalk.yellow('  ./build.sh  # Test build'));
          break;
        case 'pm-web':
          console.log(chalk.yellow('  pnpm install'));
          console.log(chalk.yellow('  pnpm dev'));
          break;
        case 'flutter':
          console.log(chalk.yellow('  flutter pub get'));
          console.log(chalk.yellow('  flutter run'));
          break;
        default:
          console.log(chalk.yellow('  Follow project-specific setup instructions'));
      }
      
      console.log(chalk.yellow('  delax-quick-pull  # Test workflow'));
      console.log('');
      console.log(chalk.green('✨ Happy coding with DELAX technical heritage!'));
      
    } catch (error) {
      console.error(chalk.red('❌ Project creation failed:'));
      console.error(error);
      process.exit(1);
    }
  });

async function collectProjectConfig(template: ProjectTemplate, name: string): Promise<ProjectConfig> {
  console.log(chalk.blue(`📋 Configuring ${template} project: ${name}`));
  console.log('');

  const baseQuestions = [
    {
      type: 'input',
      name: 'description',
      message: 'Project description:',
      default: `A ${template} project created with DELAX technical heritage`,
    },
    {
      type: 'input',
      name: 'author',
      message: 'Author:',
      default: 'DELAX',
    },
  ];

  const commonQuestions = [
    {
      type: 'confirm',
      name: 'enableSlackNotifications',
      message: 'Enable Slack notifications?',
      default: false,
    },
    {
      type: 'input',
      name: 'slackWebhook',
      message: 'Slack webhook URL:',
      when: (answers: any) => answers.enableSlackNotifications,
    },
    {
      type: 'confirm',
      name: 'enableEmailNotifications',
      message: 'Enable email notifications?',
      default: false,
    },
    {
      type: 'input',
      name: 'notificationEmail',
      message: 'Notification email:',
      when: (answers: any) => answers.enableEmailNotifications,
    },
  ];

  let specificQuestions: any[] = [];

  switch (template) {
    case 'ios-swift':
      specificQuestions = [
        {
          type: 'input',
          name: 'bundleId',
          message: 'Bundle ID:',
          default: `com.delax.${name.toLowerCase().replace(/[^a-z0-9]/g, '')}`,
          validate: (input: string) => {
            if (!/^[a-zA-Z0-9.-]+$/.test(input)) {
              return 'Bundle ID must contain only letters, numbers, dots, and hyphens';
            }
            return true;
          },
        },
        {
          type: 'confirm',
          name: 'enableClaudeKit',
          message: 'Enable ClaudeKit integration?',
          default: true,
        },
        {
          type: 'confirm',
          name: 'enableSwiftData',
          message: 'Enable SwiftData?',
          default: true,
        },
        {
          type: 'confirm',
          name: 'enableHealthKit',
          message: 'Enable HealthKit integration?',
          default: false,
        },
      ];
      break;

    case 'pm-web':
      specificQuestions = [
        {
          type: 'input',
          name: 'supabaseUrl',
          message: 'Supabase project URL:',
          validate: (input: string) => {
            if (input && !input.startsWith('https://')) {
              return 'Please enter a valid Supabase URL (https://...)';
            }
            return true;
          },
        },
        {
          type: 'confirm',
          name: 'enableRealtime',
          message: 'Enable Supabase Realtime?',
          default: true,
        },
        {
          type: 'confirm',
          name: 'enableAuth',
          message: 'Enable Supabase Auth?',
          default: true,
        },
        {
          type: 'list',
          name: 'deploymentPlatform',
          message: 'Deployment platform:',
          choices: ['Netlify', 'Vercel', 'None'],
          default: 'Netlify',
        },
      ];
      break;

    case 'flutter':
      specificQuestions = [
        {
          type: 'confirm',
          name: 'enableSupabase',
          message: 'Enable Supabase integration?',
          default: true,
        },
        {
          type: 'confirm',
          name: 'enableRiverpod',
          message: 'Enable Riverpod state management?',
          default: true,
        },
        {
          type: 'list',
          name: 'targetPlatforms',
          message: 'Target platforms:',
          choices: ['iOS & Android', 'iOS only', 'Android only'],
          default: 'iOS & Android',
        },
      ];
      break;
  }

  const answers = await inquirer.prompt([...baseQuestions, ...specificQuestions, ...commonQuestions]);

  return {
    projectName: name,
    template,
    ...answers,
  };
}

// Handle CLI errors
process.on('unhandledRejection', (error) => {
  console.error(chalk.red('❌ Unhandled error:'));
  console.error(error);
  process.exit(1);
});

program.parse();