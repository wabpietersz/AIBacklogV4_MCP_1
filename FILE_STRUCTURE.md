# Project File Structure

**Last Updated**: Pre-Day 1 (After Organization)

---

## 📂 Root Level (Essential Documents Only)

```
Chat-MCP-Jira-V1/
├── START_HERE.md                    ⭐ Entry point - Read this first!
├── README.md                         Project overview
├── MASTER_PLAN.md                   ⭐ 7-week source of truth
├── AGENT_ARCHITECTURE.md            ⭐ 5-layer architecture
├── AGENT_IMPLEMENTATION_PLAN.md     ⭐ Daily implementation guide
├── PRE_FLIGHT_CHECKLIST.md          Setup before Day 1
├── PROJECT_STATUS.md                Current status and progress
│
├── .cursorrules                     Cursor AI development rules
├── pyproject.toml                   Python dependencies and config
├── setup.sh                         One-command setup script
├── dev.sh                           Development helper commands
│
├── docs/                            📁 All documentation
├── src/                             📁 Source code (created Week 1+)
├── tests/                           📁 Tests (created Week 1+)
├── scripts/                         📁 Helper scripts
└── examples/                        📁 Example code
```

---

## 📁 Documentation (docs/)

### Organized by Type

```
docs/
├── README.md                        Documentation index
│
├── specs/                           📋 Specifications
│   ├── API_CONTRACTS.md            API specs, data models, error codes
│   └── TESTING_STRATEGY.md         Testing pyramid, coverage goals
│
├── guides/                          📖 Implementation Guides
│   ├── TECHNICAL_REVIEW.md         Technical analysis & recommendations
│   ├── DOCUMENT_ORGANIZATION.md    Navigation guide
│   └── FINAL_ORGANIZATION_SUMMARY.md Organization summary
│
├── reference/                       📚 Reference Documentation
│   ├── PHASED_APPROACH.md          Two-phase approach (Frontend)
│   ├── PHASE1_IMPLEMENTATION.md    Original MCP server plan
│   ├── ARCHITECTURE.md             Original hybrid architecture
│   ├── IMPLEMENTATION_PLAN.md      Original 9-phase plan
│   └── CLAUDE.md                   Claude Code development guide
│
└── archive/                         🗄️ Legacy Documents
    └── jira_mcp_dev_plan.md        Original planning doc (superseded)
```

---

## 📁 Source Code (src/)

**Created during Week 1**

```
src/
├── __init__.py
│
├── foundation/                      Layer 1: Generic & Reusable
│   ├── __init__.py
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── base_agent.py           BaseAgent abstract class
│   │   ├── persona.py              Persona + Permission
│   │   └── agent_response.py       Standardized response format
│   ├── mcp/
│   │   ├── __init__.py
│   │   ├── client_manager.py       MCPClientManager
│   │   ├── tool_registry.py        ToolRegistry
│   │   └── mcp_config.py           MCP server configs
│   ├── auth/
│   │   ├── __init__.py
│   │   ├── permission_checker.py   Permission validation
│   │   └── azure_ad_auth.py        Azure AD provider
│   └── utils/
│       ├── __init__.py
│       ├── logging.py              Structured logging
│       └── telemetry.py            Application Insights
│
├── agents/                          Layer 3: Persona Agents
│   ├── __init__.py
│   ├── jira/
│   │   ├── __init__.py
│   │   ├── general_user_agent.py   Limited permissions
│   │   ├── admin_agent.py          Full permissions
│   │   └── persona_configs.py      Persona definitions
│   └── base/
│       ├── __init__.py
│       └── llm_agent.py            LLM integration base
│
├── mcp_servers/                     Layer 2: MCP Servers
│   ├── __init__.py
│   └── jira/
│       ├── __init__.py
│       ├── server.py               FastMCP server
│       ├── config/
│       │   ├── __init__.py
│       │   └── jira_config.py      Jira configuration
│       ├── jira/
│       │   ├── __init__.py
│       │   ├── client.py           Jira API wrapper
│       │   ├── search.py           JQL search
│       │   ├── issues.py           CRUD operations
│       │   └── agile.py            Sprints, boards
│       └── tools/
│           ├── __init__.py
│           └── jira_tools.py       12 MCP tools
│
├── orchestration/                   Layer 4: Orchestration
│   ├── __init__.py
│   ├── orchestrator.py             OrchestratorAgent
│   ├── router.py                   Routing logic
│   └── workflow_engine.py          Multi-step workflows
│
└── main.py                          FastAPI entry point
```

---

## 📁 Tests (tests/)

**Created during Week 1**

```
tests/
├── __init__.py
│
├── unit/                            Unit tests
│   ├── __init__.py
│   ├── foundation/
│   │   ├── __init__.py
│   │   ├── test_persona.py
│   │   ├── test_base_agent.py
│   │   ├── test_mcp_client_manager.py
│   │   ├── test_tool_registry.py
│   │   └── test_permission_checker.py
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── test_general_user_agent.py
│   │   └── test_admin_agent.py
│   └── mcp_servers/
│       ├── __init__.py
│       └── test_jira_tools.py
│
├── integration/                     Integration tests
│   ├── __init__.py
│   ├── test_agent_mcp_integration.py
│   ├── test_orchestrator.py
│   └── test_end_to_end.py
│
└── fixtures/                        Test data
    ├── __init__.py
    └── sample_data.py
```

---

## 📁 Other Folders

```
scripts/                             Helper scripts
├── deploy_azure.sh                 Azure deployment
├── run_tests.sh                    Test runner
└── generate_docs.sh                Documentation generator

examples/                            Example code
├── curl_examples.sh                API examples with curl
├── python_client.py                Python client example
└── postman_collection.json         Postman collection
```

---

## File Counts

| Location | Markdown Docs | Config/Scripts | Total |
|----------|---------------|----------------|-------|
| Root | 7 | 4 | 11 |
| docs/ | 11 | 1 | 12 |
| **Total** | **18** | **5** | **23** |

---

## Quick Reference

### Essential Reading (Root)
1. START_HERE.md - Entry point
2. MASTER_PLAN.md - 7-week plan
3. AGENT_ARCHITECTURE.md - Architecture
4. AGENT_IMPLEMENTATION_PLAN.md - Daily guide
5. PRE_FLIGHT_CHECKLIST.md - Setup

### Daily Development
- AGENT_IMPLEMENTATION_PLAN.md - Your daily guide
- docs/specs/API_CONTRACTS.md - API reference
- docs/specs/TESTING_STRATEGY.md - Test patterns
- .cursorrules - Coding guidelines (Cursor reads automatically)

### Week-Specific
- **Week 1**: Foundation layer (src/foundation/)
- **Week 2**: Jira MCP server (src/mcp_servers/jira/)
- **Week 3**: Persona agents (src/agents/jira/)
- **Week 4**: Orchestrator (src/orchestration/ + src/main.py)
- **Weeks 5-7**: Frontend (see docs/reference/PHASED_APPROACH.md)

### Reference
- docs/reference/ - All reference documentation
- docs/guides/ - Technical guides and reviews
- docs/archive/ - Legacy documents

---

## Organization Principles

### Root Level
**Keep only essential documents** that are used daily:
- ✅ Entry point (START_HERE.md)
- ✅ Source of truth (MASTER_PLAN.md)
- ✅ Core architecture (AGENT_ARCHITECTURE.md)
- ✅ Daily guide (AGENT_IMPLEMENTATION_PLAN.md)
- ✅ Setup instructions (PRE_FLIGHT_CHECKLIST.md)
- ✅ Status tracking (PROJECT_STATUS.md)
- ✅ Project overview (README.md)

### docs/ Folder
**Organize by document type**:
- `specs/` - Technical specifications
- `guides/` - Implementation guides
- `reference/` - Reference documentation
- `archive/` - Legacy/superseded documents

### Code Organization
**Organize by layer**:
- `src/foundation/` - Layer 1 (generic)
- `src/mcp_servers/` - Layer 2 (MCP servers)
- `src/agents/` - Layer 3 (persona agents)
- `src/orchestration/` - Layer 4 (orchestrator)
- Frontend will be separate Next.js project (Week 5+)

---

## Benefits of This Structure

1. **Clean Root**: Only 7 essential docs + 4 config files at root
2. **Easy Navigation**: Documents organized by type in docs/
3. **Clear Separation**: Code, tests, docs, scripts all separated
4. **Scalability**: Easy to add new layers, personas, or use cases
5. **Maintainability**: Each folder has clear purpose

---

For complete documentation index, see: `docs/README.md`
