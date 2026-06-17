# OpenClaw ADHD Assistant Skill — Reference Implementation

> Source: https://github.com/matthomeiasmandr/adhd-assistant
> Author: thinktankmachine
> License: MIT
> Install: `npx clawhub@latest install adhd-assistant`

## Overview

ADHD-friendly life management assistant for OpenClaw/SkillBoss. Provides external scaffolding for executive function challenges.

## Features

1. **Daily Planning & Check-ins** — Morning planning, 1-3 priorities, time-blocked schedules with buffers
2. **Task Breakdown** — Micro-steps (2-5 min each), "next visible action" identification
3. **Time Management** — External time structure, visual timers, time-blocking, gentle recovery
4. **Prioritization** — Eisenhower Matrix, "Daily Top 3", urgent vs important
5. **Body Doubling** — Virtual co-working sessions, structured check-ins, presence-based support
6. **Dopamine Regulation** — Personalized "dopamine menus", micro-rewards, celebration prompts
7. **Emotional Support** — Shame/guilt reframing, RSD support, self-compassion
8. **End-of-Day & Weekly Reviews** — Shutdown rituals, pattern recognition, system adjustment

## Trigger Phrases

- "I can't get started"
- "I have too much to do"
- "I keep forgetting"
- "Where did the day go?"
- "I'm so disorganized"
- "I need help planning"
- "I feel overwhelmed"
- "My brain is all over the place"

## Core Principles

1. **Externalize Everything** — Time, tasks, priorities, memory
2. **Small Steps Win** — Break everything down smaller than feels necessary
3. **Progress Over Perfection** — Partial completion > perfect planning
4. **Interest-Based Motivation** — ADHD brains run on interest, not importance
5. **Gentle Accountability** — Body doubling without pressure

## Workflows

### Daily Check-In (Morning)
1. Warm-up: energy level, deadlines
2. Priority selection: 1-3 max
3. Daily structure: morning block, midday block, buffer, end-of-day capture
4. Output: task file, reminders, check-in times

### Task Breakdown
1. Clarify goal
2. Identify constraints
3. Break into micro-steps (2-5 min each)
4. If still stuck: reduce step size, suggest environment change, offer body doubling

### Body Doubling Session
- 25-50 minute sessions
- Check-in at start, midpoint, end
- User reports progress at agreed intervals

### Time Blindness Recovery
1. Normalize without blame
2. Assess what happened
3. Gently re-anchor to current time
4. Adjust schedule without self-judgment

## What We Can Borrow

| Feature | Our Implementation |
|---------|-------------------|
| Daily check-in flow | Our skill: morning assessment → priority selection → structure |
| Task breakdown | Our skill: micro-steps with ADHD buffer |
| Body doubling | Our skill: subagent-based presence sessions |
| Dopamine regulation | Our skill: gamification, celebration, streaks |
| Emotional support | Our skill: shame reframing, RSD support |
| Time blindness | Our skill: learned estimation patterns + buffer |
| Trigger phrases | Our skill: activate on ADHD-related keywords |

## What They Do Better

- **Trigger phrase detection** — comprehensive list of ADHD-related phrases
- **Emotional support scripts** — specific language for shame/guilt reframing
- **Dopamine menus** — personalized stimulation strategies
- **Shutdown rituals** — structured end-of-day capture

## What We Do Better

- **AI agent integration** — cron, subagents, messaging platforms
- **Cross-platform** — WhatsApp/Signal/Telegram, not just one platform
- **Supply chain security** — built-in audit pipeline
- **Pattern learning** — track completion patterns over time
- **Context switching recovery** — detect and resume after distraction
