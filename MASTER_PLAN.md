# Master Plan: Generic Agentic Platform

**Start Date**: Tomorrow
**Timeline**: 7 weeks
**Goal**: Production-ready platform with Jira use case

---

## 📋 Document Organization

### Read First (Understanding)
1. **README.md** - Project vision and overview
2. **AGENT_ARCHITECTURE.md** - Complete architecture (5 layers)

### Implementation Guides (Building)
3. **AGENT_IMPLEMENTATION_PLAN.md** - Week-by-week implementation guide ⭐ PRIMARY
4. **TECHNOLOGY_STACK.md** - Technology decisions and rationale
5. **API_CONTRACTS.md** - API specifications and data models

### Reference Documents
6. **PHASED_APPROACH.md** - Original two-phase approach
7. **PHASE1_IMPLEMENTATION.md** - Original MCP server plan
8. **ARCHITECTURE.md** - Original hybrid architecture
9. **CLAUDE.md** - Development guide

### Supporting Documents
10. **PRE_FLIGHT_CHECKLIST.md** - Setup before Day 1
11. **TESTING_STRATEGY.md** - Testing approach
12. **DEPLOYMENT_GUIDE.md** - Azure deployment
13. **TROUBLESHOOTING.md** - Common issues and solutions

---

## 🎯 The Vision

### What We're Building

A **generic agentic platform** where:
- Solutions are built once and reused across domains
- Agents orchestrate based on requirements and personas
- MCP servers provide specialized tools as services
- Permissions are enforced at the agent layer
- Frontend works with any persona/use case

### First Implementation

**Jira Assistant** with two personas:
- **General User Agent**: Limited to reading, creating basic items, managing own issues
- **Admin Agent**: Full project management capabilities

---

## 🏗️ Architecture Layers

### Layer 1: Foundation (Week 1) - GENERIC & REUSABLE

**Purpose**: Reusable components for ANY agentic solution

**Components**:
```python
foundation/
├── agents/
│   ├── base_agent.py          # BaseAgent abstract class
│   ├── persona.py             # Persona + Permission system
│   └── agent_response.py      # Standardized response format
├── mcp/
│   ├── client_manager.py      # Connect to multiple MCP servers
│   └── tool_registry.py       # Discover and filter tools
├── auth/
│   ├── permission_checker.py  # Validate permissions
│   └── azure_ad_auth.py       # Azure AD integration
└── utils/
    ├── logging.py             # Structured logging
    └── telemetry.py           # Application Insights
```

**Success Criteria**:
- [ ] BaseAgent can be subclassed for any use case
- [ ] Persona system works without Jira-specific logic
- [ ] MCPClientManager can connect to any MCP server
- [ ] Permission system is domain-agnostic
- [ ] 100% test coverage on foundation

### Layer 2: MCP Servers (Week 2) - SPECIALIZED TOOLS

**Purpose**: Domain-specific tools as independent services

**For Jira Use Case**:
```python
mcp_servers/jira/
├── server.py              # FastMCP server
├── config/
│   └── jira_config.py     # Jira configuration
├── jira/
│   ├── client.py          # Jira API wrapper
│   ├── search.py          # JQL search
│   ├── issues.py          # CRUD operations
│   └── agile.py           # Sprints, boards
└── tools/
    └── jira_tools.py      # 12 MCP tools
```

**12 Tools to Implement**:

Core (6):
1. `jira_search` - JQL search
2. `jira_get_issue` - Get issue details
3. `jira_create_issue` - Create issue
4. `jira_update_issue` - Update issue
5. `jira_add_comment` - Add comment
6. `jira_transition_issue` - Change status

Advanced (6):
7. `jira_delete_issue` - Delete issue (admin only)
8. `jira_get_sprints` - List sprints
9. `jira_create_sprint` - Create sprint (admin only)
10. `jira_add_worklog` - Log time
11. `jira_assign_issue` - Assign to user (admin only)
12. `jira_bulk_update` - Batch operations (admin only)

**Success Criteria**:
- [ ] All 12 tools working correctly
- [ ] Deployed to Azure Container Apps
- [ ] Health check endpoint responding
- [ ] Can be called via MCP Inspector
- [ ] Integrated with MCPClientManager

### Layer 3: Persona Agents (Week 3) - USE CASE SPECIFIC

**Purpose**: Persona-specific agents with permissions

**For Jira Use Case**:
```python
agents/jira/
├── general_user_agent.py   # Limited permissions
├── admin_agent.py          # Full permissions
└── persona_configs.py      # Persona definitions
```

**General User Persona**:
```python
Permissions:
- jira:read:* (read all issues)
- jira:write:own (write own issues only)
- jira:create:* (create issues)
- jira:comment:* (comment on all)

Allowed Tools:
- jira_search
- jira_get_issue
- jira_create_issue
- jira_update_issue (filtered to own)
- jira_add_comment
- jira_transition_issue (filtered to own)
- jira_get_sprints (read-only)
- jira_add_worklog (own issues)

Auto-filters:
- JQL: Add "assignee = currentUser()" for updates
- Cannot delete issues
- Cannot create sprints
- Cannot bulk update
```

**Admin Persona**:
```python
Permissions:
- jira:*:* (all permissions)

Allowed Tools:
- All 12 tools

Auto-filters:
- None (full access)
```

**Success Criteria**:
- [ ] General User Agent enforces permissions correctly
- [ ] Admin Agent has full access
- [ ] JQL auto-filtering works
- [ ] Permission denied errors are clear
- [ ] Unit tests cover all permission scenarios

### Layer 4: Orchestration (Week 4) - ROUTING

**Purpose**: Route requests to appropriate agents

```python
orchestration/
├── orchestrator.py         # Main orchestrator
├── router.py               # Routing logic
└── workflow_engine.py      # Multi-step workflows (future)
```

**API Endpoints**:
```
POST /execute
POST /personas (list available personas)
GET  /health
GET  /tools (list tools per persona)
```

**Success Criteria**:
- [ ] Routes to correct persona agent
- [ ] Returns persona capabilities
- [ ] Handles errors gracefully
- [ ] API documented with OpenAPI spec
- [ ] Load tested (100 concurrent requests)

### Layer 5: Frontend (Weeks 5-7) - UI

**Purpose**: Persona-aware chat interface

**Features**:
- Persona selector (General User / Admin)
- Chat interface with LLM integration
- Tool execution visualization
- Suggested prompts per persona
- Error handling (permission denied)

**Success Criteria**:
- [ ] Persona switching works
- [ ] Chat streams responses
- [ ] Shows which tools are being called
- [ ] Mobile responsive
- [ ] Sub-200ms initial load

---

## 🔧 Technology Stack

### Backend (Weeks 1-4)

**Language**: Python 3.10+
**Why**: Foundation + Jira MCP server both in Python for consistency

**Core Frameworks**:
- **FastMCP 2.0** - MCP server framework (Layer 2)
- **FastAPI** - Backend API (Layer 4)
- **Pydantic v2** - Data validation
- **Microsoft Agent Framework** - Agent orchestration (optional enhancement)

**Jira Integration**:
- **atlassian-python-api** - Proven Jira client (from mcp-atlassian)
- **httpx** - Async HTTP client

**MCP**:
- **mcp** (Python SDK) - MCP protocol implementation

**Azure**:
- **azure-identity** - Azure AD / Entra ID
- **azure-keyvault-secrets** - Secret management
- **msal** - Microsoft Authentication Library
- **applicationinsights** - Telemetry

**Testing**:
- **pytest** - Test framework
- **pytest-asyncio** - Async tests
- **pytest-cov** - Coverage
- **pytest-mock** - Mocking

**Dev Tools**:
- **ruff** - Linting + formatting
- **mypy** - Type checking
- **uv** - Fast package installer

### Frontend (Weeks 5-7)

**Framework**: Next.js 15 (App Router)
**Why**: Full-stack, built-in auth, Azure integration

**UI**:
- **React 18** - Component library
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **shadcn/ui** - Component library

**LLM Integration**:
- **Vercel AI SDK** - LLM streaming
- **Azure OpenAI** - GPT-4o

**Auth**:
- **NextAuth.js** - Authentication
- **Azure AD provider** - Enterprise SSO

**MCP Client**:
- **@modelcontextprotocol/sdk** - TypeScript MCP SDK

### Infrastructure

**Container Registry**:
- **Azure Container Registry** - Docker images

**Backend Hosting**:
- **Azure Container Apps** - MCP server (Layer 2)
- **Azure Container Apps** - API backend (Layer 4)

**Frontend Hosting**:
- **Azure Static Web Apps** - Next.js frontend

**Secrets**:
- **Azure Key Vault** - Credentials storage

**Monitoring**:
- **Application Insights** - Logs, metrics, traces

**CI/CD**:
- **GitHub Actions** - Automated deployment

---

## 📅 Week-by-Week Plan

### Week 1: Foundation Layer (5 days)

**Goal**: Generic, reusable foundation

**Day 1 (Mon)**:
- [ ] Project structure setup
- [ ] pyproject.toml configuration
- [ ] Virtual environment setup
- [ ] Create Persona + Permission classes
- [ ] Unit tests for Persona

**Day 2 (Tue)**:
- [ ] Create BaseAgent abstract class
- [ ] Create AgentResponse standardized format
- [ ] Create ToolExecution tracking
- [ ] Unit tests for BaseAgent

**Day 3 (Wed)**:
- [ ] Implement MCPClientManager
- [ ] Implement connection pooling
- [ ] Implement tool listing
- [ ] Unit tests for MCPClientManager

**Day 4 (Thu)**:
- [ ] Implement ToolRegistry
- [ ] Implement tool filtering
- [ ] Implement permission-based filtering
- [ ] Unit tests for ToolRegistry

**Day 5 (Fri)**:
- [ ] Implement PermissionChecker
- [ ] Implement JQL filtering logic
- [ ] Integration tests for foundation
- [ ] Documentation review

**Deliverable**: Generic foundation that works for ANY use case

**Test**:
```python
# Create a test persona
test_persona = Persona(
    name="test",
    permissions=[Permission("resource", "read", "*")],
    allowed_tools=["tool1", "tool2"]
)

# Create a test agent
class TestAgent(BaseAgent):
    async def execute(self, task, context):
        return AgentResponse(success=True, message="Test")

# Test it works
agent = TestAgent("test", test_persona)
assert agent.can_use_tool("tool1")
assert not agent.can_use_tool("tool3")
```

### Week 2: Jira MCP Server (5 days)

**Goal**: 12 Jira tools deployed to Azure

**Day 6 (Mon)**:
- [ ] Port JiraConfig from mcp-atlassian
- [ ] Port JiraFetcher (Jira API client)
- [ ] Implement authentication (PAT, API token)
- [ ] Unit tests for Jira client

**Day 7 (Tue)**:
- [ ] Create FastMCP server structure
- [ ] Implement 6 core tools (search, get, create, update, comment, transition)
- [ ] Test locally with MCP Inspector

**Day 8 (Wed)**:
- [ ] Implement 6 advanced tools (delete, sprints, worklog, assign, bulk)
- [ ] Add tool tags for permissions
- [ ] Test all tools with MCP Inspector

**Day 9 (Thu)**:
- [ ] Create Dockerfile
- [ ] Build and test Docker image locally
- [ ] Create Azure Container Registry
- [ ] Push image to ACR

**Day 10 (Fri)**:
- [ ] Deploy to Azure Container Apps
- [ ] Configure health checks
- [ ] Test public endpoint
- [ ] Register with MCPClientManager

**Deliverable**: Working Jira MCP server at `https://jira-mcp-server.azurecontainerapps.io/mcp`

**Test**:
```bash
# Health check
curl https://jira-mcp-server.azurecontainerapps.io/healthz

# List tools
npx @modelcontextprotocol/inspector \
  --url https://jira-mcp-server.azurecontainerapps.io/mcp

# Call tool
# (via MCP Inspector UI)
```

### Week 3: Persona Agents (5 days)

**Goal**: General User and Admin agents working

**Day 11 (Mon)**:
- [ ] Create persona_configs.py with both personas
- [ ] Define all permissions
- [ ] Define all allowed tools
- [ ] Add suggested prompts metadata

**Day 12 (Tue)**:
- [ ] Implement GeneralUserAgent skeleton
- [ ] Implement _handle_search with JQL filtering
- [ ] Implement _handle_create
- [ ] Test search and create

**Day 13 (Wed)**:
- [ ] Implement _handle_comment
- [ ] Implement _handle_update with ownership check
- [ ] Implement _handle_transition with ownership check
- [ ] Test permission enforcement

**Day 14 (Thu)**:
- [ ] Implement AdminAgent
- [ ] Add all 12 tools to admin
- [ ] Test admin has full access
- [ ] Test general user restrictions work

**Day 15 (Fri)**:
- [ ] Integration tests (agent → MCP server)
- [ ] Performance tests
- [ ] Error handling improvements
- [ ] Documentation

**Deliverable**: Two persona agents with correct permissions

**Test**:
```python
# General User
general_agent = GeneralUserAgent(mcp_manager)
response = await general_agent.execute(
    "Show my assigned bugs",
    {"email": "user@example.com", "persona": "general_user"}
)
assert response.success

# Try to delete (should fail)
response = await general_agent.execute(
    "Delete issue JB-123",
    {"email": "user@example.com"}
)
assert not response.success
assert "permission" in response.error.lower()

# Admin
admin_agent = AdminAgent(mcp_manager)
response = await admin_agent.execute(
    "Delete issue JB-123",
    {"email": "admin@example.com", "persona": "admin"}
)
assert response.success
```

### Week 4: Orchestrator + API (5 days)

**Goal**: FastAPI backend with routing

**Day 16 (Mon)**:
- [ ] Create OrchestratorAgent
- [ ] Implement agent registration
- [ ] Implement routing logic
- [ ] Unit tests for orchestrator

**Day 17 (Tue)**:
- [ ] Create FastAPI app
- [ ] Implement POST /execute endpoint
- [ ] Implement GET /personas endpoint
- [ ] Implement GET /health endpoint

**Day 18 (Wed)**:
- [ ] Add Azure AD authentication
- [ ] Add request validation
- [ ] Add error handling
- [ ] Add rate limiting

**Day 19 (Thu)**:
- [ ] Create OpenAPI spec
- [ ] Add CORS configuration
- [ ] Deploy to Azure Container Apps
- [ ] Test public endpoint

**Day 20 (Fri)**:
- [ ] Load testing (100 concurrent users)
- [ ] API documentation
- [ ] Integration tests
- [ ] Week 1-4 retrospective

**Deliverable**: Backend API deployed and tested

**Test**:
```bash
# List personas
curl https://api.example.com/personas

# Execute as general user
curl -X POST https://api.example.com/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "task": "Show my assigned bugs",
    "persona": "general_user",
    "user_email": "user@example.com"
  }'

# Execute as admin
curl -X POST https://api.example.com/execute \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "task": "Create a new sprint",
    "persona": "admin",
    "user_email": "admin@example.com"
  }'
```

### Week 5: Frontend Setup (5 days)

**Goal**: Next.js app with persona selector

**Day 21 (Mon)**:
- [ ] Create Next.js 15 project
- [ ] Setup TypeScript, Tailwind, shadcn/ui
- [ ] Configure Azure AD authentication
- [ ] Create base layout

**Day 22 (Tue)**:
- [ ] Create Persona selector component
- [ ] Fetch personas from API
- [ ] Store selected persona in state
- [ ] Create persona switcher UI

**Day 23 (Wed)**:
- [ ] Create chat layout
- [ ] Create message components
- [ ] Setup separate context per persona
- [ ] Test persona switching

**Day 24 (Thu)**:
- [ ] Create MCP client wrapper
- [ ] Test API connectivity
- [ ] Handle authentication tokens
- [ ] Error handling

**Day 25 (Fri)**:
- [ ] Create suggested prompts per persona
- [ ] Create persona info cards
- [ ] Mobile responsive design
- [ ] Frontend testing

**Deliverable**: Frontend skeleton with persona switching

### Week 6: Chat Interface (5 days)

**Goal**: Working chat with LLM

**Day 26 (Mon)**:
- [ ] Setup Vercel AI SDK
- [ ] Create chat API route
- [ ] Integrate Azure OpenAI
- [ ] Test LLM streaming

**Day 27 (Tue)**:
- [ ] Implement chat input
- [ ] Implement message streaming
- [ ] Display assistant responses
- [ ] Handle tool calls

**Day 28 (Wed)**:
- [ ] Create tool execution visualization
- [ ] Show which tools are being called
- [ ] Display tool parameters
- [ ] Show tool results

**Day 29 (Thu)**:
- [ ] Handle permission errors
- [ ] Show "switch persona" suggestions
- [ ] Implement retry logic
- [ ] Error boundaries

**Day 30 (Fri)**:
- [ ] Chat history persistence
- [ ] Export conversation
- [ ] Clear chat per persona
- [ ] Testing and bug fixes

**Deliverable**: Functional chat interface

### Week 7: Polish + Deploy (5 days)

**Goal**: Production-ready application

**Day 31 (Mon)**:
- [ ] Direct Jira operations UI (optional)
- [ ] Issue browser
- [ ] Create issue form
- [ ] View issue details

**Day 32 (Tue)**:
- [ ] Admin dashboard (optional)
- [ ] Usage metrics
- [ ] Tool execution logs
- [ ] User management

**Day 33 (Wed)**:
- [ ] Performance optimization
- [ ] Lighthouse score > 90
- [ ] Bundle size optimization
- [ ] Caching strategy

**Day 34 (Thu)**:
- [ ] Deploy to Azure Static Web Apps
- [ ] Configure custom domain
- [ ] SSL certificates
- [ ] CDN configuration

**Day 35 (Fri)**:
- [ ] End-to-end testing
- [ ] User acceptance testing
- [ ] Documentation finalization
- [ ] Launch! 🚀

**Deliverable**: Production deployment

---

## ✅ Success Criteria

### Week 1: Foundation
- [ ] All unit tests passing (100% coverage)
- [ ] BaseAgent can be subclassed for any use case
- [ ] Persona system is domain-agnostic
- [ ] MCPClientManager can connect to any MCP server
- [ ] Code reviewed and documented

### Week 2: Jira MCP Server
- [ ] All 12 tools working correctly
- [ ] Deployed to Azure Container Apps
- [ ] Health check responding
- [ ] Can be tested with MCP Inspector
- [ ] Integrated with foundation layer

### Week 3: Persona Agents
- [ ] General User permissions enforced
- [ ] Admin has full access
- [ ] JQL filtering works correctly
- [ ] Permission errors are clear
- [ ] Integration tests passing

### Week 4: Orchestrator
- [ ] Routes to correct agent
- [ ] API documented with OpenAPI
- [ ] Handles 100 concurrent requests
- [ ] Error handling robust
- [ ] Deployed to Azure

### Week 5: Frontend Setup
- [ ] Persona selector working
- [ ] Authentication with Azure AD
- [ ] Mobile responsive
- [ ] Separate contexts per persona

### Week 6: Chat Interface
- [ ] LLM streaming responses
- [ ] Tool execution visible
- [ ] Permission errors handled gracefully
- [ ] Chat history working

### Week 7: Production
- [ ] Lighthouse score > 90
- [ ] End-to-end tests passing
- [ ] Deployed to production
- [ ] Monitoring configured
- [ ] Documentation complete

---

## 🔍 Quality Gates

Each week must pass these gates before moving to next week:

### Code Quality
- [ ] All tests passing
- [ ] No linting errors (ruff)
- [ ] No type errors (mypy)
- [ ] Code coverage > 80%

### Documentation
- [ ] All new code documented
- [ ] API changes documented
- [ ] README updated if needed

### Security
- [ ] No secrets in code
- [ ] Permissions tested
- [ ] OWASP top 10 checked

### Performance
- [ ] No N+1 queries
- [ ] Response time < 500ms p95
- [ ] Memory leaks checked

---

## 📊 Risk Mitigation

### Risk 1: Foundation Too Generic
**Risk**: Foundation becomes overly abstract
**Mitigation**:
- Build for Jira first, extract patterns second
- Test with mock second use case (HR)
- Keep interfaces simple

### Risk 2: LLM Tool Selection
**Risk**: LLM doesn't choose correct tools
**Mitigation**:
- Start with keyword matching
- Add LLM gradually
- Have explicit examples in prompts

### Risk 3: Permission Complexity
**Risk**: Permission system too complex
**Mitigation**:
- Start with simple allow/deny
- Add scopes incrementally
- Test exhaustively

### Risk 4: Azure Costs
**Risk**: Development costs too high
**Mitigation**:
- Use minimal replicas (1)
- Auto-scale down to 0 for dev
- Monitor costs daily

### Risk 5: Scope Creep
**Risk**: Adding too many features
**Mitigation**:
- Stick to 7-week timeline
- Mark features as "future"
- MVP first, polish later

---

## 📦 Dependencies

### External Services Required
- [ ] Azure subscription
- [ ] Jira instance (Cloud or Server)
- [ ] Jira API token or PAT
- [ ] Azure AD tenant
- [ ] GitHub account (for CI/CD)

### Before Day 1
- [ ] Azure subscription active
- [ ] Jira credentials obtained
- [ ] Development environment setup
- [ ] Access to Azure portal
- [ ] Docker installed locally

---

## 🎯 North Star Metrics

### Technical Metrics
- **Foundation Reusability**: Can add new use case in < 1 week
- **API Latency**: p95 < 500ms
- **Test Coverage**: > 80%
- **Uptime**: > 99.9%

### Product Metrics
- **Persona Accuracy**: Permission errors < 5%
- **User Satisfaction**: "Can do my task" > 90%
- **Tool Success Rate**: > 95%

### Business Metrics
- **Time to New Use Case**: < 1 week
- **Development Velocity**: 1 use case per sprint
- **Code Reuse**: > 70% of foundation reused

---

This master plan is your source of truth. All other documents support this plan.

**Tomorrow**: Start with Week 1, Day 1 from AGENT_IMPLEMENTATION_PLAN.md
