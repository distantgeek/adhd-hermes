# ADHD Executive Function — Landscape Research Report

> Date: 2026-06-16
> Research method: GitHub API search, web_fetch, README analysis
> Scope: Existing tools, projects, skills for ADHD executive function support

---

## 1. DEDICATED ADHD PROJECTS

### 1.1 Ilseon (cladam/ilseon) — ⭐12
**Platform:** Android (Kotlin/Jetpack Compose)
**URL:** https://github.com/cladam/ilseon

**What it does:**
- Minimalist executive function assistant designed to reduce mental overload
- Context filtering — choose one life context (Work/Family/Personal), everything else hides
- Single priority view — shows only the current/next task
- Sub-task breakdown — sequential steps, hides master task when focused
- Quick capture — floating action button for instant task entry
- Idea inbox — captures non-actionable mental clutter (transient + persistent views)
- Voice inbox — voice memos transcribed via Gemini API
- Momentum analytics — daily consistency tracking, reward levels
- Gentle reminders — vibration/visual cues, not noisy alerts

**Key design principles:**
- Simplicity is success — whitespace, quiet colors, clean typography
- Focus first — only one visible task at a time
- Distraction-minimal UI

**What we can borrow:**
- Context filtering (show only relevant tasks for current context)
- Single priority view (ONE thing, not a list)
- Gentle reminder patterns (escalating, not aggressive)
- Momentum/consistency tracking with positive reinforcement
- Voice capture for quick thought externalization

**Limitations:** Android-only, no AI agent integration, no body doubling

---

### 1.2 NousAI (keown-work/nous) — ⭐0
**Platform:** React Native + Expo (iOS & Android)
**URL:** https://github.com/keown-work/nous

**What it does:**
- AI-powered executive function coach for adults with ADHD
- Conversational AI coach with task breakdown
- Smart task breakdown — large tasks → manageable steps with time estimates
- Focus sessions — Pomodoro timer with ambient sounds, AI check-ins, streaks
- Daily dashboard — mood check-in, energy slider, priorities, habits
- Emotional regulation — breathing exercises, grounding tools, brain dump journal
- Habit & routine builder — morning/evening routines, streaks
- Gamification — XP system, achievement badges, levels, daily streaks

**Tech stack:** React Native, Supabase, OpenAI GPT-4o, Zustand

**What we can borrow:**
- Mood-based task adaptation (adjust breakdown based on current state)
- Focus sessions with AI check-ins
- Emotional regulation tools (breathing, grounding, brain dump)
- Gamification (XP, streaks, badges) — dopamine hits for ADHD brains
- Daily dashboard with mood + energy tracking

**Limitations:** Requires Supabase + OpenAI API keys, mobile-only, no desktop/agent integration

---

### 1.3 The Smart Companion (Piyushkr1210/The-Smart-Companion) — ⭐1
**Platform:** Python + Streamlit (web app)
**URL:** https://github.com/Piyushkr1210/The-Smart-Companion

**What it does:**
- AI-assisted productivity for neurodivergent individuals (ADHD, Autism, Executive Dysfunction)
- Mood-based AI planning — user selects mood (Calm/Low Energy/Overwhelmed/Motivated)
- AI adapts task breakdown: Low energy → ultra tiny steps, Overwhelmed → calming steps
- Local LLM via Ollama (qwen2.5:7b) — offline, private
- Voice input via Vosk (offline speech recognition)
- Gamified productivity — points, streaks, progress bar, celebration animation
- Data export — JSON download, SQLite storage

**What we can borrow:**
- Mood-based task adaptation (directly applicable to our skill)
- Offline-first design (privacy, no cloud dependency)
- Celebration animations (dopamine hits)
- Voice input for quick capture

**Limitations:** Web app only (Streamlit), requires Ollama locally, no agent/cron integration

---

### 1.4 CosmiCoach (thecosmicskye/CosmiCoach) — ⭐8
**Platform:** iOS (SwiftUI)
**URL:** https://github.com/thecosmicskye/CosmiCoach

**What it does:**
- iOS app using Claude 3.7 for ADHD coaching
- Apple Calendar + Reminders integration
- Persistent memory (markdown file) for AI to learn about user over time
- Proactive task prioritization
- Daily check-ins for basics (medication, eating, drinking water)
- Pattern analysis for task completion
- Minimizes decision fatigue — asks one question at a time

**What we can borrow:**
- Daily check-in pattern (medication, food, water — basic needs tracking)
- Pattern analysis (learn user's completion patterns over time)
- One-question-at-a-time interaction (reduces decision fatigue)
- Persistent memory via markdown (simple, effective)

**Limitations:** iOS-only, requires Claude API key, Apple ecosystem lock-in

---

### 1.5 TimeBox-Buddy (carpeicthus/TimeBox-Buddy) — ⭐0
**Platform:** Web (Google AI Studio / Gemini)
**URL:** https://github.com/carpeicthus/TimeBox-Buddy

**What it does:**
- AI-driven scheduling engine optimized for ADHD and executive function support
- Built on Gemini API

**What we can borrow:** Concept of ADHD-optimized scheduling
**Limitations:** Minimal info available, appears to be a demo/wrapper

---

## 2. RELATED PRODUCTIVITY TOOLS

### 2.1 Task Coach (taskcoach/taskcoach) — ⭐31
**URL:** https://github.com/taskcoach/taskcoach
- Free, open-source task manager
- Project organization, time tracking, recurring tasks
- Desktop app (Python/wxPython)
- **Relevance:** Good reference for task data model, but not ADHD-specific

### 2.2 Natural Language Planner (bparticle/natural-language-planner) — ⭐1
**URL:** https://github.com/bparticle/natural-language-planner
- OpenClaw skill: natural conversation → organized tasks/projects
- Local-first (Markdown + YAML files)
- Kanban dashboard at localhost:8080
- Proactive check-ins for stale tasks
- **Relevance:** Very relevant — similar concept to what we're building, but no ADHD-specific features

---

## 3. OPENCLAW MARKETPLACE

### 3.1 ADHD Assistant (matthomeiasmandr/adhd-assistant)
**URL:** https://github.com/matthomeiasmandr/adhd-assistant
**Install:** `npx clawhub@latest install adhd-assistant`
**Also listed on:** https://openclawskills.wiki/skill/adhd-assistant

**What it does:**
- ADHD-friendly life management assistant for OpenClaw/SkillBoss
- Daily planning & check-ins (morning planning, 1-3 priorities, time-blocked schedules with buffers)
- Task breakdown into micro-steps (2-5 min each)
- Time management with time blindness support
- Prioritization (Eisenhower Matrix, Daily Top 3)
- Body doubling sessions (25-50 min virtual co-working)
- Dopamine regulation (personalized "dopamine menus", micro-rewards)
- Emotional support (shame/guilt reframing, RSD support)
- End-of-day & weekly reviews

**Trigger phrases:** "I can't get started", "I have too much to do", "I keep forgetting", "Where did the day go?", "I'm so disorganized", "I need help planning", "I feel overwhelmed", "My brain is all over the place"

**Core principles:** Externalize everything, small steps win, progress over perfection, interest-based motivation, gentle accountability

**What we can borrow:** Trigger phrase detection, emotional support scripts, dopamine menus, shutdown rituals, body doubling session structure

**What we do better:** AI agent integration (cron, subagents, messaging), cross-platform (WhatsApp/Signal/Telegram), supply chain security, pattern learning, context switching recovery

### 3.2 OpenClaw Skills Store (中文)
- General productivity skills but no additional ADHD-specific ones
- Confirms the space is underserved — only one ADHD skill exists, and it's SkillBoss-specific

---

## 4. ACADEMIC RESEARCH (via Semantic Scholar / arXiv)

Key research areas to investigate:
- **Barkley's Executive Function Model** — foundational ADHD EF theory
- **Brown's ADHD Model** — attention regulation framework
- **Diamond's Executive Functions** — cognitive flexibility, working memory, inhibitory control
- **ADHD Coaching Interventions** — evidence-based coaching approaches
- **Digital Therapeutics for ADHD** — FDA-cleared and in-development
- **Time Perception in ADHD** — time blindness research
- **Body Doubling** — social facilitation for task initiation

---

## 5. KEY PATTERNS ACROSS ALL TOOLS

### What works (common across successful tools):
1. **Single focus** — show ONE task, not a list (reduces overwhelm)
2. **Mood-aware adaptation** — adjust approach based on current state
3. **Micro-steps** — break tasks into tiny, concrete actions
4. **Gentle escalation** — reminders that increase in intensity, not volume
5. **Positive reinforcement** — streaks, XP, celebration (dopamine)
6. **Externalization** — get thoughts out of head → into system
7. **Time estimation with buffer** — ADHD time blindness requires 1.5-2x buffer
8. **Context switching** — separate work/personal/project contexts
9. **Body doubling** — presence of another agent/person for accountability
10. **Pattern learning** — track completion patterns, adapt over time

### What's missing (gaps we can fill):
- **AI agent integration** — no tool uses a full AI agent with cron, subagents, messaging
- **Cross-platform** — most are mobile-only or web-only
- **Messaging integration** — no tool integrates with WhatsApp/Signal/Telegram
- **Body doubling via AI** — no tool uses an AI agent as a body double
- **Escalating nagging** — no tool has intelligent reminder escalation
- **Time blindness compensation** — no tool learns your time estimation patterns
- **Context switching recovery** — no tool helps you pick up where you left off after distraction

---

## 6. RECOMMENDATIONS FOR OUR SKILL

Based on this research, our ADHD executive function skill should differentiate by:

1. **AI agent as body double** — unique capability (subagent stays "present" while you work)
2. **Multi-platform messaging** — WhatsApp/Signal/Telegram integration (not just mobile app)
3. **Intelligent nagging** — escalating reminders that learn your response patterns
4. **Time blindness correction** — learn your estimation patterns, apply ADHD buffer
5. **Context switching recovery** — detect distraction, help you resume
6. **Mood-based adaptation** — adjust task breakdown based on current state (from Smart Companion)
7. **Gamification** — streaks, celebration, dopamine hits (from NousAI)
8. **Single priority view** — ONE thing at a time (from Ilseon)
9. **Voice capture** — quick thought externalization (from Ilseon/Smart Companion)
10. **Pattern learning** — track completion patterns, adapt over time (from CosmiCoach)
