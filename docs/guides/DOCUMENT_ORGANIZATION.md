# Document Organization Guide

**Purpose**: Understand which documents to read and when

---

## Document Classification

### 🎯 Essential - Read Before Day 1

These documents are **required reading** before you start building tomorrow:

| Document | Purpose | Time | Priority |
|----------|---------|------|----------|
| **START_HERE.md** | Complete organization guide | 5 min | **MUST READ** |
| **AGENT_ARCHITECTURE.md** | 5-layer architecture | 15 min | **MUST READ** |
| **MASTER_PLAN.md** | 7-week source of truth | 10 min | **MUST READ** |
| **PRE_FLIGHT_CHECKLIST.md** | Setup before Day 1 | 1-2 hours | **MUST COMPLETE** |

**Total Time**: ~2 hours

### 📘 Implementation Guides - Daily Use

Use these documents during development:

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **AGENT_IMPLEMENTATION_PLAN.md** | Week-by-week code examples | Daily (your main guide) |
| **API_CONTRACTS.md** | API specifications | Week 4 (API development) |
| **TESTING_STRATEGY.md** | Testing approach | Daily (while writing tests) |
| **TECHNICAL_REVIEW.md** | Technical recommendations | Week 1-2 (architecture decisions) |

### 📚 Reference - As Needed

Reference these when you need additional context:

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **README.md** | Project overview | Quick reference |
| **PHASED_APPROACH.md** | Two-phase approach | Week 5-7 (frontend design) |
| **PHASE1_IMPLEMENTATION.md** | Original MCP plan | Week 2 (Jira MCP server) |
| **ARCHITECTURE.md** | Original hybrid architecture | Week 2 (MCP patterns) |
| **IMPLEMENTATION_PLAN.md** | Original 9-phase plan | Feature reference |
| **CLAUDE.md** | Development guide | Future Claude sessions |

### 🗄️ Legacy - Archive

These documents are superseded but kept for reference:

| Document | Status | Notes |
|----------|--------|-------|
| **jira_mcp_dev_plan.md** | ⚠️ Superseded | Original planning doc (1.6K) |

**Recommendation**: Move to `docs/archive/` folder

---

## Reading Strategy

### First Time Setup (Today)

1. **START_HERE.md** (5 min) - Get oriented
2. **AGENT_ARCHITECTURE.md** (15 min) - Understand the layers
3. **MASTER_PLAN.md** (10 min) - Know the 7-week plan
4. **PRE_FLIGHT_CHECKLIST.md** (1-2 hours) - Complete setup

**Total**: ~2 hours

### Daily Workflow (During Implementation)

**Morning**:
1. Open **AGENT_IMPLEMENTATION_PLAN.md**
2. Find current week and day
3. Review tasks for the day

**During Development**:
- Reference **AGENT_IMPLEMENTATION_PLAN.md** for code examples
- Reference **API_CONTRACTS.md** for data models
- Reference **TESTING_STRATEGY.md** for test patterns

**End of Day**:
- Check **MASTER_PLAN.md** quality gates
- Update progress in **PROJECT_STATUS.md**

### Weekly Workflow

**End of Each Week**:
1. Review **MASTER_PLAN.md** success criteria
2. Complete quality gates checklist
3. Plan next week from **AGENT_IMPLEMENTATION_PLAN.md**

---

## File Consolidation Plan

### Files to Keep As-Is ✅

All core documents are well-organized and should remain:
- START_HERE.md
- MASTER_PLAN.md
- AGENT_ARCHITECTURE.md
- AGENT_IMPLEMENTATION_PLAN.md
- API_CONTRACTS.md
- TESTING_STRATEGY.md
- PRE_FLIGHT_CHECKLIST.md
- PROJECT_STATUS.md
- TECHNICAL_REVIEW.md

### Files to Move to Archive

Create `docs/archive/` and move:
```bash
mkdir -p docs/archive
mv jira_mcp_dev_plan.md docs/archive/
```

### Optional: Consolidate Reference Docs

If you want fewer files, you could combine:
- ARCHITECTURE.md + PHASE1_IMPLEMENTATION.md → docs/reference/LEGACY_MCP_PLANS.md
- IMPLEMENTATION_PLAN.md → docs/reference/ORIGINAL_9_PHASE_PLAN.md
- PHASED_APPROACH.md → Keep (needed for frontend)

**Recommendation**: Keep all for now, consolidate later if needed

---

## Quick Reference

### "I want to..."

**...understand the vision**
→ READ: AGENT_ARCHITECTURE.md

**...start coding**
→ READ: AGENT_IMPLEMENTATION_PLAN.md → Week 1

**...know what to build today**
→ READ: AGENT_IMPLEMENTATION_PLAN.md → Current Week → Current Day

**...understand API contracts**
→ READ: API_CONTRACTS.md

**...write tests**
→ READ: TESTING_STRATEGY.md

**...deploy to Azure**
→ READ: PRE_FLIGHT_CHECKLIST.md (Week 2+: PHASE1_IMPLEMENTATION.md Week 5)

**...build the frontend**
→ READ: PHASED_APPROACH.md Phase 2

**...add a new use case (e.g., HR)**
→ READ: AGENT_ARCHITECTURE.md → "Extensibility" section

---

## Document Dependencies

```
START_HERE.md (entry point)
    ├── README.md (overview)
    ├── AGENT_ARCHITECTURE.md (architecture) ⭐
    │   └── Used by: All implementation work
    ├── MASTER_PLAN.md (7-week plan) ⭐
    │   └── References: AGENT_IMPLEMENTATION_PLAN.md
    ├── AGENT_IMPLEMENTATION_PLAN.md (daily guide) ⭐
    │   ├── References: API_CONTRACTS.md
    │   ├── References: TESTING_STRATEGY.md
    │   └── Used by: Daily development
    ├── PRE_FLIGHT_CHECKLIST.md (setup)
    └── Reference Docs/
        ├── PHASED_APPROACH.md (frontend design)
        ├── PHASE1_IMPLEMENTATION.md (MCP server)
        ├── ARCHITECTURE.md (original hybrid)
        └── IMPLEMENTATION_PLAN.md (9-phase)
```

---

## Document Sizes

| Document | Size | Type |
|----------|------|------|
| AGENT_IMPLEMENTATION_PLAN.md | 30K | Implementation |
| TESTING_STRATEGY.md | 29K | Implementation |
| AGENT_ARCHITECTURE.md | 24K | Core |
| PHASE1_IMPLEMENTATION.md | 23K | Reference |
| MASTER_PLAN.md | 20K | Core |
| API_CONTRACTS.md | 17K | Implementation |
| PHASED_APPROACH.md | 17K | Reference |
| ARCHITECTURE.md | 16K | Reference |
| CLAUDE.md | 12K | Reference |
| IMPLEMENTATION_PLAN.md | 12K | Reference |
| README.md | 11K | Core |
| START_HERE.md | 11K | Core |
| PRE_FLIGHT_CHECKLIST.md | 10K | Setup |
| PROJECT_STATUS.md | 9K | Status |
| TECHNICAL_REVIEW.md | 15K | Review |
| **Total** | **~256K** | **15 files** |

---

## Maintenance

### Keeping Documents in Sync

As you build, update:
- **PROJECT_STATUS.md** - After each week
- **README.md** - If architecture changes
- **AGENT_IMPLEMENTATION_PLAN.md** - If you discover better patterns

### Deprecation Strategy

If a document becomes outdated:
1. Add "⚠️ SUPERSEDED" to the title
2. Add note at top pointing to replacement
3. Move to `docs/archive/`

Example:
```markdown
# ⚠️ SUPERSEDED: Original Planning Doc

**This document is superseded by MASTER_PLAN.md**

See: MASTER_PLAN.md for the current 7-week plan.

---

[Original content below]
```

---

## Summary

**Core Documents (5)**: START_HERE.md, MASTER_PLAN.md, AGENT_ARCHITECTURE.md, AGENT_IMPLEMENTATION_PLAN.md, PRE_FLIGHT_CHECKLIST.md

**Implementation Guides (3)**: API_CONTRACTS.md, TESTING_STRATEGY.md, TECHNICAL_REVIEW.md

**Reference (6)**: README.md, PHASED_APPROACH.md, PHASE1_IMPLEMENTATION.md, ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, CLAUDE.md

**Status (1)**: PROJECT_STATUS.md

**Legacy (1)**: jira_mcp_dev_plan.md

**Total**: 16 documents, ~256K

---

**You have everything you need. Start building tomorrow! 🚀**
