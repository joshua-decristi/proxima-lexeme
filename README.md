# Proxima Lexeme

## AI-Powered Contextual Vocabulary Learning System

### Design Document & Business Overview

---

**Version**: 1.0
**Date**: February 2026
**Status**: Design Complete

---

## Executive Summary

Proxima Lexeme is an intelligent vocabulary acquisition system that solves the fundamental problem language learners face: **the gap between drowning in incomprehensible content and learning isolated words without context**.

Unlike traditional flashcard apps that teach words in isolation, or immersive content that overwhelms beginners with too many unknown terms, Proxima Lexeme uses artificial intelligence to generate personalized study material—sentences that contain the perfect mix of familiar and new vocabulary for each learner's current level.

The system tracks progress not at the word level (where "run" and "ran" are separate entries), but at the **lexeme level**—the complete word family. This means mastering "run" as a concept includes understanding run, ran, running, runner, and runs as interconnected forms, weighted by their real-world usage frequency.

**Key Innovation**: Context-as-flashcard. Every study session presents 1-2 sentences in the target language. The learner reads, guesses meanings, reveals answers, and self-assesses. The AI then generates the next context based on updated mastery scores, creating a continuous, adaptive learning loop.

---

## The Problem

### Drowning vs. Isolation

Language learners face a false choice:

**Option 1: Drowning**
Immersing in native content (books, movies, conversations) with 30-50% unknown vocabulary. The cognitive load is overwhelming. Learners can't parse sentences, miss grammatical patterns, and frustration leads to abandonment.

**Option 2: Isolation**
Traditional flashcard apps teach words in isolation: "perro = dog." This creates a library of discrete facts without understanding how words function in sentences. Learners know vocabulary but can't read or communicate.

**The Gap**: Targeted vocabulary learning WITH context. Material that's comprehensible enough to parse, but challenging enough to grow.

### Why Existing Solutions Fall Short

- **Duolingo/Babbel**: Gamified but rigid curricula, not personalized to user's actual vocabulary gaps
- **Anki/Memrise**: Isolated flashcards without context
- **Readers**: Static content doesn't adapt to learner's growing vocabulary
- **Tutors**: Expensive and not scalable

---

## The Solution: Context-Based Adaptive Learning

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    STUDY SESSION FLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. OPEN → Context immediately displayed                    │
│     "El perro corre rápido por el parque."                  │
│                                                             │
│  2. READ → Learner guesses meanings                         │
│     • Recognizes "perro" (dog) - learned yesterday          │
│     • Unsure about "corre" - highlighted target word        │
│                                                             │
│  3. REVEAL → Shows translations & scores                    │
│     • corre = runs (Score: 0.65)                            │
│     • rápido = fast (Score: 0.40)                           │
│                                                             │
│  4. GRADE → Self-assessment 1-5 scale                       │
│     [1] [2] [3] [4] [5]                                     │
│                                                             │
│  5. UPDATE → Scores adjust, next context selected           │
│     • "corre" score increases to 0.75                       │
│     • System selects next optimal context                   │
│                                                             │
│  6. REPEAT → New context displayed                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### The Three Word Categories

Every generated context contains a strategic mix:

#### Target Words (3-7 per context)

Words the learner is actively studying—highlighted in the interface. The number adapts to context length:

- **1 sentence**: 3-4 target words (avoids overcrowding)
- **2 sentences**: 5-7 target words (more room to distribute naturally)

These are selected from the learner's "studying" vocabulary—words they've encountered but haven't mastered yet.

#### Anchor Words (0-N per context)

Words the learner knows reasonably well (scores 0.7+) that provide scaffolding. They make the sentence comprehensible without being the focus. Beginners might have few anchors; advanced learners have many.

#### Filler Words (0-N per context)

Additional words needed to create grammatically correct, natural sentences. These can be any words in the learner's vocabulary—even completely unknown ones. The anti-drowning protection (see below) manages cognitive load at the lexeme level, not the word level.

---

## Core Concepts

### Lexemes: The Unit of Mastery

**Definition**: A lexeme is a word family—all forms sharing a common meaning.

**Example**: The lexeme RUN includes:

- **Base form**: run (verb)
- **Past tense**: ran
- **Present participle**: running
- **Agent noun**: runner
- **Third person**: runs
- **Adjective**: runnable

**Why This Matters**:
Traditional apps track "run" and "ran" separately. Proxima Lexeme tracks them as interconnected parts of the RUN lexeme, weighted by usage frequency. The learner must encounter all forms, but mastery emphasizes common forms over rare derivatives.

**Polysemy Handling**:
"Running" belongs to multiple lexemes depending on meaning:

- "I am running" → RUN (physical movement)
- "Running water" → FLOW (continuous motion)
- "Running for office" → CAMPAIGN (political activity)

The system tracks which lexeme is being learned based on context.

### Scoring System: From Encounter to Mastery

#### Word-Translation Score (0.0 - 1.0)

Tracks mastery of a specific word form + meaning pair.

**Updates via Self-Grading:**
| Grade | Meaning | Adjustment |
|-------|---------|------------|
| 1 | Complete failure | -0.2 |
| 2 | Poor recall | -0.1 |
| 3 | Partial recall | 0.0 |
| 4 | Good recall | +0.1 |
| 5 | Perfect recall | +0.2 |

Scores are clamped between 0.0 and 1.0.

#### Lexeme Score: Weighted by Real-World Usage

The lexeme score is a weighted average of all word-translation scores within that lexeme, where weights represent frequency of use:

```
Lexeme Score = Σ(Word Score × Frequency Weight) / Σ(Frequency Weights)
```

**Example**: RUN lexeme

- "run" (verb): 50% of usage, score 0.95
- "ran" (past): 25% of usage, score 0.80
- "running" (gerund): 15% of usage, score 0.85
- "runner" (noun): 8% of usage, score 0.60
- "runs" (3rd person): 2% of usage, score 0.70

Lexeme Score = (0.95×0.50) + (0.80×0.25) + (0.85×0.15) + (0.60×0.08) + (0.70×0.02)
= 0.475 + 0.200 + 0.1275 + 0.048 + 0.014
= 0.8645

Since 0.8645 < 0.9, the RUN lexeme is **not yet mastered**, despite high scores on the most common form.

#### The 0.9 Threshold: "Known" Status

A lexeme is considered "known" when:

1. Lexeme score ≥ 0.9
2. ALL word forms have been encountered at least once

This ensures comprehensive mastery—you can't "know" RUN without seeing "ran" and "runner" in context, but your overall score emphasizes the forms you'll actually use.

#### Encounter vs. Mastery

**Encounter**: Seeing a word form in any context (tracked separately from score)
**Mastery**: High score + multiple encounters across different contexts

A word might be encountered 10 times with poor recall (low score) or encountered 3 times with perfect recall (high score). Both metrics matter.

---

## Anti-Drowning Protection

### The 25-Lexeme Limit

To prevent cognitive overload, the system limits active learning load:

**Rule**: Maximum 25 lexemes in "studying" state (score < 0.9) at any time.

**Behavior**:

- If < 25 studying lexemes: Can introduce new lexeme from frequency list
- If ≥ 25 studying lexemes: Must review existing ones until some reach "known"

**Why This Works**:
Research shows humans can actively learn 20-30 new concepts simultaneously before interference and forgetting accelerate. By capping at 25 lexemes (potentially 50-100 word forms), Proxima Lexeme stays in the optimal zone for vocabulary acquisition.

The constraint is on **lexemes**, not individual words. A context might contain 10 unknown word forms from 3 lexemes—this is fine. But 10 unknown word forms from 10 different lexemes would violate the limit.

---

## Progress Tracking

### Primary Metric: Known Lexeme Count

**Display**: "47 / 10,000 lexemes known"

This is the single most important number. It represents:

- Comprehensive word family mastery
- Weighted toward practical usage (common forms count more)
- Based on consistent recall (not just exposure)

**Why Lexemes, Not Words?**

- 10,000 lexemes ≈ 25,000-50,000 word forms
- Native speaker vocabulary: ~20,000 lexemes
- Tracking lexemes provides a realistic path from beginner to fluency

### Adaptive Learning Path

The system introduces lexemes in frequency order:

1. **The** (rank 1) — encountered first
2. **Be** (rank 2) — encountered second
3. **And** (rank 3) — encountered third
4. ...continuing through most frequent words

Within each lexeme, word forms are introduced by frequency:

1. "run" (base verb, 50% of usage)
2. "ran" (past tense, 25% of usage)
3. "running" (gerund, 15% of usage)
4. ...continuing through less common forms

**Result**: Maximum practical vocabulary gain from every minute of study.

---

## Context Generation: The AI Engine

### How Contexts Are Created

**Input**: Lists of words provided by the selection algorithm
**Process**: Large Language Model generates natural sentences using those words
**Output**: Target-language sentence + base-language translation

**The Prompt** (simplified):

```
Generate 1-2 sentences in Spanish that:
1. Include these target words: [corre, parque, rápido]
2. Use these anchor words for scaffolding: [perro, el, por]
3. Make sense grammatically and semantically
4. Are appropriate for language learning (clear context)

Return in JSON format with translation.
```

**Provider**: OpenRouter API (access to GPT-4, Claude, and other models)

**Constraints**:

- Must include all selected target words
- Should be natural, not forced
- Vocabulary limited to learner's known/studying words
- Length appropriate to number of target words

### Quality Assurance

Generated contexts are validated to ensure:

- All target words actually appear
- Sentence is grammatically correct
- Meaning is clear from context
- Difficulty matches learner's level

If generation fails, the system retries with adjusted parameters.

---

## System Architecture Overview

### Components

**Study Interface** (Progressive Web App)

- Opens directly to context (no "start session" button)
- Mobile-optimized for phone study
- Works offline with cached content
- Installs to home screen like native app

**Context Engine** (AI Service)

- Selects optimal word mix for each learner
- Generates natural sentences via LLM
- Adapts to learner's evolving vocabulary

**Progress System** (Database)

- Tracks word-translation scores
- Calculates lexeme mastery
- Enforces anti-drowning limits
- Provides progress metrics

**Data Import**

- Frequency-ranked word lists (user-provided)
- Lemmatized lexicons (user-provided)
- Language-agnostic architecture (works with any language pair)

### Technology Foundation

**Backend**: Gleam programming language

- Functional, type-safe
- Compiles to Erlang VM (proven for concurrent systems)
- Growing ecosystem, excellent error messages

**Database**: PostgreSQL

- Relational data fits lexeme/word structure naturally
- ACID transactions for score updates
- Scales to 100,000+ lexemes

**Frontend**: Data-Star framework

- Reactive UI components
- Compiles from Gleam to JavaScript
- Type-safe throughout

**Styling**: UnoCSS

- On-demand utility classes
- Smaller bundles than traditional CSS frameworks
- Fast hot-reload during development

**AI Integration**: OpenRouter API

- Unified interface to multiple LLMs
- Cost-effective model routing
- Automatic fallback between providers

---

## The Learning Experience

### For a Complete Beginner (Day 1)

**Context**: "El perro corre." (The dog runs.)

- **Target words**: 3 words from first 1-2 lexemes (el, perro, corre)
- **Anchor words**: None (nothing known yet)
- **Result**: Mostly unknown, but that's expected

The learner sees "el" and "perro" repeatedly in early contexts, building recognition before moving to new lexemes.

### For an Intermediate Learner (Month 3)

**Context**: "El perro corre rápido por el parque mientras el sol brilla."
(The dog runs fast through the park while the sun shines.)

- **Target words**: 3-5 from studying set (rápido, parque, mientras, sol, brilla)
- **Anchor words**: Known words (el, perro, corre, por)
- **Result**: Mix of familiar and new, comprehensible but challenging

### For an Advanced Learner (Year 1)

**Context**: "A pesar de la lluvia torrencial, el maratonista persistente siguió corriendo con determinación inquebrantable."
(Despite the torrential rain, the persistent marathon runner kept running with unwavering determination.)

- **Target words**: 5-7 advanced vocabulary words
- **Anchor words**: Mostly known words providing structure
- **Result**: Complex sentences with precise vocabulary

At every level, the context is tailored to the learner's current vocabulary—never too easy (boring), never too hard (frustrating).

---

## Business Model & Use Cases

### Primary Use Case: Personal Language Learning

**Target User**: Serious language learners who have struggled with traditional methods

**Value Proposition**:

- Learn 10,000+ lexemes (25,000-50,000 word forms)
- Always at the optimal difficulty level
- Context-based retention (words learned in sentences stick better)
- Efficient path from beginner to fluency

### Secondary Use Cases

**Language Teachers**

- Assign targeted vocabulary practice
- Track student progress via lexeme counts
- Supplement classroom instruction

**Polyglots**

- Maintain multiple languages simultaneously
- Quick vocabulary review before travel
- Efficient use of limited study time

**Researchers**

- Data on vocabulary acquisition patterns
- Frequency-weighted learning curves
- Spaced repetition optimization (future)

### Competitive Advantages

1. **Lexeme-Based Tracking**: More sophisticated than word-level apps
2. **AI-Generated Contexts**: Infinitely adaptable content vs. static curricula
3. **Frequency-Weighted Scoring**: Prioritizes practical vocabulary
4. **Anti-Drowning Protection**: Optimal cognitive load management
5. **Context-as-Flashcard**: Superior retention vs. isolated words

---

## Implementation Overview

### Development Timeline: 6 Weeks

**Week 1**: Database & Data Model

- PostgreSQL schema design
- Migration system setup
- Lexicon import functionality
- Sample data population

**Week 2**: Core Logic & API

- Word selection algorithm
- Score calculation engine
- Anti-drowning enforcement
- REST API endpoints

**Week 3**: AI Integration

- OpenRouter API client
- Context generation prompts
- Quality validation
- Error handling & retries

**Week 4**: User Interface

- Mobile-first PWA design
- Context display component
- Reveal & grading interface
- Progress visualization

**Week 5**: Integration & Testing

- Frontend-backend wiring
- Offline support
- End-to-end testing
- Performance optimization

**Week 6**: Deployment

- Docker containerization
- Documentation
- Mobile testing
- Production readiness

### Success Metrics

**Functional**:

- Context generation < 5 seconds
- Database queries < 200ms
- Supports 100,000+ lexemes
- Works offline on mobile

**User Experience**:

- Can study for 30 minutes without errors
- Intuitive self-grading interface
- Clear progress visibility
- Smooth context transitions

**Learning Efficacy**:

- Users reach 100 known lexemes within first week
- Retention rates superior to flashcard apps
- User reports of "finally making progress"

---

## Future Directions

### Near-Term Enhancements

**Context Caching**: Pre-generate contexts to reduce LLM costs and enable offline study

**Spaced Repetition**: Review words before they're forgotten, based on forgetting curves

**Adaptive Difficulty**: Longer contexts and complex sentences as learner advances

**Import/Export**: Anki deck import, progress backup, data portability

### Long-Term Vision

**Multi-Modal Contexts**: Dialogues, paragraphs, image descriptions

**Real-World Integration**: Learn from actual content (news, books, menus) with comprehension assistance

**Speech Integration**: Pronunciation practice with speech recognition

**Community Features**: Shared contexts, leaderboards, study groups

---

## Conclusion

Proxima Lexeme represents a fundamental shift in vocabulary acquisition:

**From**: Isolated flashcards OR drowning in content
**To**: Targeted, contextual learning at the perfect difficulty level

**From**: Word-level tracking (run ≠ ran)
**To**: Lexeme-level mastery with frequency weighting

**From**: Static curricula OR one-size-fits-all
**To**: AI-generated, personalized contexts that adapt in real-time

The system treats vocabulary not as a list to memorize, but as a dynamic ecosystem to explore—always at the boundary between comfort and challenge, where learning happens fastest.

For serious language learners who have struggled with traditional methods, Proxima Lexeme offers a path from 0 to 10,000+ lexemes that's efficient, engaging, and effective.

---

**Status**: Design Complete | Ready for Implementation

**Next Step**: Begin development Phase 1 (Database & Data Model)
