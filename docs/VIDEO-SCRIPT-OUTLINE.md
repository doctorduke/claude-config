# Video Script Outlines for GitHub Actions Self-Hosted Runner Tutorials

Professional video scripts with narration, screen actions, timestamps, and key points for creating engaging tutorial videos.

---

# Video 1: 5-Minute Quick Start

**Title**: "GitHub Actions Self-Hosted Runners in 5 Minutes"
**Duration**: 5:00
**Audience**: Developers new to self-hosted runners
**Goal**: Get first runner online and working

## Script Overview

| Timestamp | Duration | Section |
|-----------|----------|---------|
| 00:00-00:15 | 15s | Hook & Introduction |
| 00:15-00:45 | 30s | What & Why |
| 00:45-02:00 | 75s | Runner Installation |
| 02:00-03:30 | 90s | First Workflow |
| 03:30-04:30 | 60s | See It Work |
| 04:30-05:00 | 30s | Next Steps |

## Detailed Script

### [00:00-00:15] Hook & Introduction

**Screen**: Split screen - GitHub-hosted runner taking 6 minutes vs self-hosted taking 2 minutes

**Narration**:
"What if I told you that you could make your GitHub Actions workflows run 3 times faster and 77% cheaper? In the next 5 minutes, I'll show you exactly how to deploy your first self-hosted runner and see immediate results."

**Screen Actions**:
- Show side-by-side comparison
- Highlight time difference
- Transition to title card

**Key Points**:
- Hook with concrete benefits
- Set clear expectation (5 minutes)
- Promise immediate value

### [00:15-00:45] What & Why

**Screen**: Architecture diagram animation

**Narration**:
"GitHub Actions normally runs your workflows on GitHub's servers. But with self-hosted runners, you use your own compute - giving you more control, better performance, and significant cost savings. Think of it as having your own personal CI/CD server that GitHub can command. Let me show you how easy it is to set up."

**Screen Actions**:
- Animate diagram showing GitHub-hosted vs self-hosted
- Highlight benefits as bullet points appear
- Transition to terminal

**Key Points**:
- Simple explanation
- Clear value proposition
- Visual reinforcement

### [00:45-02:00] Runner Installation

**Screen**: Terminal window in WSL

**Narration**:
"First, we'll download and configure our runner. I'm using WSL on Windows, but this works on any Linux system. Let's create our workspace and download the runner package."

**Screen Actions**:
```bash
# Show typing these commands
mkdir ~/actions-runner && cd ~/actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz
tar xzf actions-runner-linux-x64-2.319.1.tar.gz
```

**Narration** (continued):
"Now we need a registration token from GitHub. Go to your organization settings, click Actions, then Runners, and copy this token."

**Screen Actions**:
- Switch to browser
- Navigate to: Settings → Actions → Runners → New self-hosted runner
- Highlight and copy token
- Switch back to terminal

**Narration** (continued):
"Now let's configure our runner with this token."

**Screen Actions**:
```bash
./config.sh --url https://github.com/YOUR_ORG --token YOUR_TOKEN
# Show prompts and responses
```

**Key Points**:
- Each command is clearly visible
- Pause on important steps
- Show actual token retrieval

### [02:00-03:30] First Workflow

**Screen**: Split view - VS Code and terminal

**Narration**:
"With our runner online, let's create a workflow that uses it. I'll create a simple workflow that showcases the speed difference."

**Screen Actions** (VS Code):
```yaml
# Type out this workflow
name: Speed Test
on: push
jobs:
  test:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v4
        with:
          sparse-checkout: src/
      - run: |
          echo "Running on self-hosted runner!"
          echo "Start time: $(date)"
```

**Narration** (continued):
"Notice the 'runs-on' field - we're specifically targeting our self-hosted runner with these labels. Now let's commit and push to trigger it."

**Screen Actions**:
```bash
git add .github/workflows/speed-test.yml
git commit -m "Add speed test workflow"
git push
```

**Key Points**:
- Highlight runs-on label
- Show sparse-checkout benefit
- Keep it simple

### [03:30-04:30] See It Work

**Screen**: GitHub Actions tab in browser

**Narration**:
"Let's watch it run. Notice how quickly it starts - under 30 seconds instead of the usual minute or more. And look at the checkout step - it's using sparse checkout to only get what we need, making it 70% faster."

**Screen Actions**:
- Navigate to Actions tab
- Click on running workflow
- Expand steps to show timing
- Highlight key metrics

**Narration** (continued):
"The entire workflow completed in just 45 seconds! On GitHub-hosted runners, this same workflow would take 2-3 minutes. That's a 3x improvement, and we're just getting started."

**Screen Actions**:
- Show completed workflow
- Compare with previous GitHub-hosted run
- Highlight time saved

**Key Points**:
- Real-time demonstration
- Specific metrics
- Tangible improvement

### [04:30-05:00] Next Steps

**Screen**: Resource links and call-to-action

**Narration**:
"Congratulations! You now have a self-hosted runner saving you time and money. But this is just the beginning. In the description, you'll find links to add AI-powered code reviews, automatic fixes, and advanced optimizations that can make your workflows even faster. Subscribe for more DevOps acceleration tips, and drop a comment with your performance improvements!"

**Screen Actions**:
- Display resource links
- Show subscribe button animation
- End card with channel branding

**Key Points**:
- Clear next actions
- Additional resources
- Engagement call-to-action

## Production Notes

### Visual Style
- Clean, minimal terminal theme
- High contrast for readability
- Smooth transitions between screens
- Highlight commands being typed

### Audio
- Clear, enthusiastic narration
- Background music: subtle tech/electronic
- Sound effects for transitions
- Terminal typing sounds (subtle)

### Key Techniques
- Speed up repetitive typing
- Pause on important information
- Use callouts for critical commands
- Include progress indicators

---

# Video 2: 15-Minute Deep Dive

**Title**: "Master GitHub Actions Self-Hosted Runners: Complete Guide"
**Duration**: 15:00
**Audience**: DevOps engineers and platform teams
**Goal**: Comprehensive understanding and production deployment

## Script Overview

| Timestamp | Duration | Section |
|-----------|----------|---------|
| 00:00-00:30 | 30s | Introduction & Agenda |
| 00:30-02:00 | 90s | Architecture Deep Dive |
| 02:00-05:00 | 180s | Production Deployment |
| 05:00-08:00 | 180s | AI Integration |
| 08:00-11:00 | 180s | Performance Optimization |
| 11:00-13:30 | 150s | Monitoring & Operations |
| 13:30-14:30 | 60s | Cost Analysis |
| 14:30-15:00 | 30s | Conclusion & Resources |

## Detailed Script

### [00:00-00:30] Introduction & Agenda

**Screen**: Professional intro with agenda items

**Narration**:
"Welcome to the complete guide for GitHub Actions self-hosted runners. Whether you're managing CI/CD for a small team or enterprise organization, by the end of this video, you'll have production-ready runners processing workflows at blazing speed with AI-powered automation. Here's what we'll cover..."

**Screen Actions**:
- Display agenda with timestamps
- Show expected outcomes
- Preview impressive metrics

**Key Points**:
- Set expectations
- Build credibility
- Preview value

### [00:30-02:00] Architecture Deep Dive

**Screen**: Animated architecture diagram

**Narration**:
"Let's start with understanding the architecture. Self-hosted runners are essentially agents that poll GitHub for work. When a workflow targets specific labels, GitHub assigns it to a matching runner."

**Screen Actions**:
- Animate connection flow
- Show polling mechanism
- Demonstrate job assignment
- Highlight security boundaries

**Narration** (continued):
"The beauty is in the flexibility. You can run these on any infrastructure - physical servers, VMs, containers, even Raspberry Pis. They communicate over HTTPS only, so they work behind firewalls and NAT."

**Screen Actions**:
- Show different deployment options
- Highlight network requirements
- Display security model

**Key Points**:
- Clear architecture understanding
- Flexibility emphasis
- Security awareness

### [02:00-05:00] Production Deployment

**Screen**: Terminal with multiple tabs

**Narration**:
"Now let's deploy a production-grade setup with 5 runners for high availability. I'll use our automated setup script that handles everything."

**Screen Actions**:
```bash
# Show script execution
./setup-runner.sh --org YOUR_ORG --token TOKEN --runner-id 1
# Fast-forward through installation
# Show systemd service status
```

**Narration** (continued):
"We'll deploy runners with different labels for different workloads. This gives us intelligent routing - PR reviews go to dedicated runners, while builds use others."

**Screen Actions**:
- Deploy multiple runners with different labels
- Show GitHub UI with all runners online
- Demonstrate label-based routing

**Key Points**:
- Production considerations
- High availability setup
- Workload segregation

### [05:00-08:00] AI Integration

**Screen**: VS Code with AI workflow

**Narration**:
"Here's where it gets exciting. We'll add AI-powered code reviews that automatically analyze every PR. Watch as I configure an AI agent that understands your codebase."

**Screen Actions**:
```yaml
# Show AI workflow configuration
name: AI PR Review
on: pull_request
jobs:
  review:
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - name: AI Review
        env:
          AI_API_KEY: ${{ secrets.AI_API_KEY }}
        run: |
          ./scripts/ai-review.sh
```

**Narration** (continued):
"Let's see it in action. I'll create a PR with intentional security issues and watch the AI catch them."

**Screen Actions**:
- Create PR with vulnerable code
- Show AI review being posted
- Highlight specific issues found
- Show approval on good code

**Key Points**:
- Real AI capabilities
- Practical examples
- Security focus

### [08:00-11:00] Performance Optimization

**Screen**: Performance monitoring dashboard

**Narration**:
"Now let's optimize for maximum speed. The biggest win? Sparse checkout. Instead of cloning the entire repository, we only get what we need."

**Screen Actions**:
```yaml
# Show optimization techniques
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      src/
      tests/
    sparse-checkout-cone-mode: false
```

**Narration** (continued):
"Let's run our benchmark suite and see the improvements."

**Screen Actions**:
- Run benchmark workflow
- Show metrics dashboard
- Compare before/after
- Highlight 85% improvement

**Key Points**:
- Quantifiable improvements
- Specific techniques
- Real metrics

### [11:00-13:30] Monitoring & Operations

**Screen**: Grafana dashboard

**Narration**:
"Production systems need monitoring. I'll show you how to track runner health, job queues, and performance metrics in real-time."

**Screen Actions**:
- Show monitoring dashboard
- Demonstrate alert configuration
- Display queue depth metrics
- Show cost tracking

**Narration** (continued):
"This dashboard tells us everything - which runners are busy, average job duration, queue depth, even cost per workflow. You can catch issues before they impact developers."

**Key Points**:
- Operational visibility
- Proactive monitoring
- Cost awareness

### [13:30-14:30] Cost Analysis

**Screen**: Spreadsheet with cost comparison

**Narration**:
"Let's talk money. With GitHub-hosted runners, you pay $0.008 per minute after your free tier. For a team running 10,000 minutes monthly, that's $80. With self-hosted runners? Zero GitHub charges, plus about $5 in infrastructure costs. That's a 94% reduction."

**Screen Actions**:
- Show cost breakdown
- Calculate ROI
- Display savings over time
- Project annual savings

**Key Points**:
- Concrete savings
- ROI calculation
- Scalability benefits

### [14:30-15:00] Conclusion & Resources

**Screen**: Resource links and summary

**Narration**:
"You now have the knowledge to deploy production-grade self-hosted runners with AI automation. Your workflows will run 3x faster at 94% less cost. In the description, you'll find scripts, configurations, and a complete guide. If this helped you, please subscribe and share with your team. What performance improvements are you seeing? Let me know in the comments!"

**Screen Actions**:
- Display key achievements
- Show resource links
- Include social links
- End card with subscribe button

**Key Points**:
- Reinforce value delivered
- Provide clear next steps
- Encourage engagement

## Production Notes

### Visual Elements
- Picture-in-picture for explanations
- Screen annotations for emphasis
- Smooth transitions between sections
- Progress bar for video sections

### B-Roll Suggestions
- Data center footage (for infrastructure discussion)
- Speed comparison animations
- Cost calculator graphics
- Team collaboration shots

### Graphics Needed
- Architecture diagrams
- Performance charts
- Cost comparison tables
- Monitoring dashboards

---

# Video 3: 10-Minute Troubleshooting Guide

**Title**: "Fix GitHub Actions Runner Issues in Minutes"
**Duration**: 10:00
**Audience**: Engineers facing runner issues
**Goal**: Solve common problems quickly

## Script Overview

| Timestamp | Duration | Section |
|-----------|----------|---------|
| 00:00-00:20 | 20s | Problem Introduction |
| 00:20-02:00 | 100s | Runner Not Picking Up Jobs |
| 02:00-03:30 | 90s | Permission Denied Errors |
| 03:30-05:00 | 90s | Performance Issues |
| 05:00-06:30 | 90s | Network Problems |
| 06:30-08:00 | 90s | AI Service Failures |
| 08:00-09:30 | 90s | Recovery Procedures |
| 09:30-10:00 | 30s | Prevention Tips |

## Detailed Script

### [00:00-00:20] Problem Introduction

**Screen**: Error messages montage

**Narration**:
"Runner not picking up jobs? Workflows failing with permission errors? AI reviews timing out? Don't worry - I've been there. In the next 10 minutes, I'll show you how to diagnose and fix the most common GitHub Actions runner issues."

**Screen Actions**:
- Quick montage of error messages
- Transition to solution promise
- Display video outline

**Key Points**:
- Acknowledge frustration
- Promise quick solutions
- Set clear expectations

### [00:20-02:00] Runner Not Picking Up Jobs

**Screen**: Terminal and GitHub UI side by side

**Narration**:
"The most common issue - jobs queuing forever. First, let's check if the runner is actually online."

**Screen Actions**:
```bash
# Check runner status
sudo ./svc.sh status
# Shows: inactive (dead) - Problem identified!
```

**Narration** (continued):
"Runner's not running! Let's fix that. But first, let's check why it stopped."

**Screen Actions**:
```bash
# Check logs
journalctl -u actions.runner.* -n 50
# Show actual error in logs

# Fix: Restart the runner
sudo ./svc.sh start

# Verify it's working
sudo ./svc.sh status
# Shows: active (running)
```

**Narration** (continued):
"But what if the runner is online and jobs still aren't running? Check the labels!"

**Screen Actions**:
- Show workflow with specific labels
- Show runner configuration with different labels
- Fix label mismatch
- Jobs immediately start running

**Key Points**:
- Systematic diagnosis
- Common cause: label mismatch
- Quick verification steps

### [02:00-03:30] Permission Denied Errors

**Screen**: Workflow logs showing permission error

**Narration**:
"Getting 'Resource not accessible by integration' errors? This means your workflow doesn't have the right permissions. GitHub recently changed defaults to read-only."

**Screen Actions**:
```yaml
# Show the fix
permissions:
  contents: read
  pull-requests: write  # Add this!
  issues: write        # If needed
```

**Narration** (continued):
"For protected branches, GITHUB_TOKEN won't work. You need a Personal Access Token."

**Screen Actions**:
- Show PAT creation in GitHub settings
- Add as secret
- Update workflow to use PAT
- Show successful push to protected branch

**Key Points**:
- Permissions are explicit now
- PAT for protected branches
- Least privilege principle

### [03:30-05:00] Performance Issues

**Screen**: Slow workflow execution

**Narration**:
"Workflows taking forever? Let's fix that. The biggest culprit? Full repository checkouts."

**Screen Actions**:
```yaml
# Before: 2 minutes
- uses: actions/checkout@v4

# After: 15 seconds
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      src/
      tests/
```

**Narration** (continued):
"Next, check for cache misses. Every cache miss means re-downloading dependencies."

**Screen Actions**:
- Show cache configuration
- Check cache hit rate
- Fix cache key issues
- Show improved performance

**Key Points**:
- Sparse checkout is crucial
- Cache configuration matters
- Measure improvements

### [05:00-06:30] Network Problems

**Screen**: Connection timeout errors

**Narration**:
"Can't connect to GitHub? Let's diagnose network issues systematically."

**Screen Actions**:
```bash
# Test connectivity
curl -I https://api.github.com
# Times out

# Check DNS
nslookup github.com
# DNS failure

# Fix DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Test again
curl -I https://api.github.com
# Success!
```

**Narration** (continued):
"Behind a corporate proxy? Configure it properly."

**Screen Actions**:
```bash
export https_proxy=http://proxy:8080
export no_proxy=localhost,127.0.0.1
```

**Key Points**:
- Systematic network debugging
- Common DNS issues
- Proxy configuration

### [06:30-08:00] AI Service Failures

**Screen**: AI timeout error

**Narration**:
"AI reviews timing out or failing? Usually it's one of three things: API key issues, rate limits, or timeout configuration."

**Screen Actions**:
```bash
# Test AI API directly
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $AI_API_KEY" \
  -d '{"model":"claude-3-sonnet-20240229","messages":[{"role":"user","content":"test"}]}'

# Check rate limit headers
# x-ratelimit-remaining: 0  # Problem found!
```

**Narration** (continued):
"Rate limited! Let's add retry logic with exponential backoff."

**Screen Actions**:
- Show retry implementation
- Add rate limit handling
- Demonstrate successful retry

**Key Points**:
- Direct API testing
- Rate limit awareness
- Retry strategies

### [08:00-09:30] Recovery Procedures

**Screen**: Emergency recovery terminal

**Narration**:
"When things go really wrong, here's your emergency recovery playbook."

**Screen Actions**:
```bash
# Nuclear option: Full reset
# 1. Stop all runners
for i in {1..5}; do sudo ~/actions-runner-$i/svc.sh stop; done

# 2. Clear all workspaces
find ~/actions-runner-*/_work -type d -exec rm -rf {} +

# 3. Clear caches
gh cache delete --all

# 4. Restart runners
for i in {1..5}; do sudo ~/actions-runner-$i/svc.sh start; done
```

**Narration** (continued):
"This clears everything and gives you a fresh start. Use it when you can't identify the specific issue."

**Key Points**:
- Last resort option
- Complete cleanup
- Fresh start

### [09:30-10:00] Prevention Tips

**Screen**: Best practices checklist

**Narration**:
"Prevention is better than cure. Set up monitoring to catch issues early. Use our automated health checks. Document your configuration. And always test changes in a non-production runner first. Check the description for monitoring scripts and a complete troubleshooting guide. Subscribe for more DevOps tips, and comment with issues you've faced - I'll cover them in future videos!"

**Screen Actions**:
- Display prevention checklist
- Show monitoring dashboard
- Include resource links
- End card

**Key Points**:
- Proactive monitoring
- Documentation importance
- Community support

## Production Notes

### Troubleshooting Footage
- Real error messages (sanitized)
- Actual debugging sessions
- Before/after comparisons
- Success celebrations

### Visual Aids
- Error message callouts
- Solution highlights
- Command annotations
- Success indicators

### Pacing
- Quick problem identification
- Steady solution explanation
- Fast verification
- Clear transitions

---

# General Production Guidelines

## Equipment Recommendations

### Video
- **Resolution**: 1080p minimum, 4K preferred
- **Frame Rate**: 60fps for screen recordings
- **Screen Capture**: OBS Studio or similar
- **Editing**: DaVinci Resolve, Premiere Pro, or Final Cut

### Audio
- **Microphone**: USB condenser or XLR with interface
- **Room Treatment**: Acoustic panels or blankets
- **Processing**: Noise removal, compression, EQ
- **Background Music**: 15-20% volume, royalty-free

## Recording Tips

### Screen Recording
1. **Clean Desktop**: Remove distracting icons
2. **Large Text**: Terminal font size 14+
3. **High Contrast**: Dark theme with bright text
4. **Smooth Actions**: Practice commands beforehand
5. **Hide Sensitive Info**: Blur tokens, emails

### Narration
1. **Script Practice**: Read through 3 times
2. **Energy Level**: Enthusiastic but professional
3. **Pacing**: Slightly slower than conversation
4. **Clarity**: Emphasize technical terms
5. **Breathing**: Pause at punctuation

## Post-Production

### Editing Checklist
- [ ] Remove dead space
- [ ] Add chapter markers
- [ ] Include captions/subtitles
- [ ] Add end screen elements
- [ ] Create custom thumbnail
- [ ] Export in multiple qualities

### Graphics and Overlays
- Terminal command highlights
- Important concept callouts
- Progress indicators
- Subscribe reminders
- Resource link overlays

## Publishing Strategy

### YouTube Optimization
- **Title**: Include "GitHub Actions" and benefit
- **Description**: Full resource list with timestamps
- **Tags**: GitHub, DevOps, CI/CD, Automation
- **Thumbnail**: Clear text, contrasting colors
- **End Screen**: Subscribe + related video

### Cross-Promotion
- Share in GitHub Discussions
- Post in relevant subreddits
- LinkedIn article with embed
- Twitter thread with key points
- Dev.to article with video embed

## Success Metrics

### Performance Indicators
- **Retention**: >50% average view duration
- **Engagement**: >5% like rate
- **Comments**: Technical discussions
- **Shares**: Team/organization sharing
- **Implementation**: Users reporting success

### Feedback Integration
- Monitor comments for common issues
- Create follow-up videos for questions
- Update descriptions with clarifications
- Pin helpful comment threads
- Engage with community

---

# Script Templates

## Introduction Template
"[Hook with problem/benefit]. In the next [duration], I'll show you [specific outcome]. By the end, you'll [capability gained]."

## Transition Template
"Now that we've [completed section], let's move on to [next section] where you'll learn [benefit]."

## Conclusion Template
"You've just learned [key skills]. Your [metric] will improve by [percentage]. Find all resources in the description. If this helped, [call to action]. What [relevant question]? Let me know in the comments!"

---

**Video Production Guide Version**: 1.0.0
**Last Updated**: 2025-10-17
**Total Runtime**: 30 minutes of content
**Estimated Production Time**: 10-15 hours

*Remember: The best tutorial is one that solves a real problem. Focus on delivering value, and the views will follow.*