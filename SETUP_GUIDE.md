# DELAX Shared Packages - Setup Guide

## 🚀 Quick Start for MyProjects Development

Now that the technical heritage repository is established, you can immediately accelerate your MyProjects iOS development:

### 1. Clone and Setup MyProjects

```bash
# Create MyProjects directory
mkdir MyProjects
cd MyProjects

# Copy technical heritage configuration
curl -o delax-config.yml https://raw.githubusercontent.com/DELAxGithub/delax-shared-packages/main/examples/myprojects-config.yml

# Initialize with DELAX workflow scripts
npm install -g @delax/workflow-scripts
# OR use locally
git clone https://github.com/DELAxGithub/delax-shared-packages.git .delax
```

### 2. Immediate Benefits

With DELAX technical heritage, your MyProjects development gets:

- **95% faster setup** (2-3 days → 30 minutes)
- **Proven iOS workflows** from 100 Days Workout
- **Claude integration** for AI-assisted development
- **Smart notifications** for development events
- **Quality assurance** with automated checks

### 3. Development Workflow

```bash
# Create feature request (GitHub issue)
gh issue create --title "Add AI task breakdown for travel planning" --body "@claude Please implement AI-powered task breakdown for travel planning projects"

# Claude automatically creates PR with implementation
# Review and merge PR when ready

# Sync changes locally
delax-quick-pull
# or if not globally installed:
./scripts/quick-pull.sh

# Open in Xcode and test
open MyProjects.xcodeproj
```

## 📦 Using Shared Packages

### Option 1: Global Installation (Recommended)

```bash
# Install workflow scripts globally
npm install -g @delax/workflow-scripts

# Create new project with generator
npm install -g @delax/project-generator
delax-create ios-swift MyProjects
```

### Option 2: Local Usage

```bash
# Clone shared packages as submodule
git submodule add https://github.com/DELAxGithub/delax-shared-packages.git .delax

# Use scripts directly
./.delax/packages/workflow-scripts/scripts/quick-pull.sh
./.delax/packages/workflow-scripts/scripts/notify.sh build-recommended
```

### Option 3: Copy Scripts (For Existing Projects)

```bash
# Copy workflow scripts to existing project
curl -o scripts/quick-pull.sh https://raw.githubusercontent.com/DELAxGithub/delax-shared-packages/main/packages/workflow-scripts/scripts/quick-pull.sh
curl -o scripts/notify.sh https://raw.githubusercontent.com/DELAxGithub/delax-shared-packages/main/packages/workflow-scripts/scripts/notify.sh
curl -o delax-config.yml https://raw.githubusercontent.com/DELAxGithub/delax-shared-packages/main/examples/myprojects-config.yml

chmod +x scripts/*.sh
```

## 🏗️ Repository Structure

```
delax-shared-packages/
├── packages/
│   └── workflow-scripts/          # Extracted from 100DaysWorkout
│       ├── scripts/
│       │   ├── quick-pull.sh      # Smart git pull + notifications
│       │   └── notify.sh          # Cross-platform notifications
│       └── src/                   # TypeScript API
├── tools/
│   └── project-generator/         # CLI for new projects
│       ├── src/
│       └── templates/
├── examples/
│   └── myprojects-config.yml      # MyProjects configuration
└── .github/workflows/
    ├── claude.yml                 # Claude auto-correction
    └── packages-check.yml         # Quality assurance
```

## ⚙️ Configuration

### Environment Variables

Set these for full functionality:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
export NOTIFICATION_EMAIL="your@email.com"
export DELAX_PROJECT_NAME="MyProjects"
export DELAX_PROJECT_TYPE="ios-swift"
```

### Project Configuration

Create `delax-config.yml` in your project root:

```yaml
project:
  name: "MyProjects"
  type: "ios-swift"

notifications:
  slack:
    webhook_url: "${SLACK_WEBHOOK_URL}"
  macos:
    enabled: true

ios:
  bundle_id: "com.delax.myprojects"
  features:
    claudekit: true
    swiftdata: true
```

## 🎯 Next Steps for MyProjects

1. **Create MyProjects repository** using the generator or manually
2. **Copy the sample configuration** from `examples/myprojects-config.yml`
3. **Set up GitHub secrets** for Claude integration:
   ```bash
   gh secret set CLAUDE_ACCESS_TOKEN
   gh secret set CLAUDE_REFRESH_TOKEN
   gh secret set CLAUDE_EXPIRES_AT
   ```
4. **Start development** with proven workflow patterns
5. **Use @claude mentions** in issues for AI-assisted development

## 📊 Expected Impact

Based on 100 Days Workout results, MyProjects development should see:

- **Setup Time**: 2-3 days → 30 minutes (95% reduction)
- **Issue Resolution**: Manual implementation → AI-assisted PRs
- **Quality Assurance**: Manual testing → Automated checks
- **Development Flow**: Context switching → Streamlined workflow

## 🤝 Contributing to Technical Heritage

As you develop MyProjects, consider contributing back:

1. **SwiftUI Components**: Reusable UI patterns
2. **AI Integration Patterns**: Task breakdown algorithms
3. **Workflow Improvements**: Enhanced automation
4. **Template Updates**: Better project generation

---

🤖 **DELAX Technical Heritage - Powered by Claude Code Integration**

Ready to accelerate your MyProjects development with 95% time savings!