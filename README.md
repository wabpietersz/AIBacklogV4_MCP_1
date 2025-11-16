# Generic Agentic Platform (Jira Use Case)

**Build once, reuse everywhere** - A generic, composable agentic platform where agents orchestrate based on requirements, personas define capabilities, and MCP servers provide specialized tools.

**First Use Case**: Jira project management with persona-based agents (General User & Admin)

## 🎯 Project Vision

### The Platform

Build a **reusable foundation** for agentic solutions:
- **Generic foundation layer** - Reusable across any use case
- **Persona-based agents** - Define capabilities and permissions
- **MCP server ecosystem** - Specialized tools as services
- **Intelligent orchestration** - Route tasks to appropriate agents
- **Unified frontend** - Works with any agent

### First Implementation: Jira Assistant

Two persona-based agents for Jira:
- **General User Agent**: Read info, create basic items, manage own issues
- **Admin Agent**: Full project management capabilities

## 🏗️ Current Status

**Phase 1**: Backend (Week 1 of 4)

Building the foundation layer for ANY agentic solution

## 🚀 Quick Start (Phase 1)

### Prerequisites
- Python 3.10+
- Azure account
- Jira Cloud or Server instance
- Jira API token or Personal Access Token

### Setup

```bash
# 1. Clone and setup
git clone <repository>
cd Chat-MCP-Jira-V1
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# 2. Install dependencies
pip install -e ".[dev]"

# 3. Configure environment
cp .env.example .env
# Edit .env with your Jira credentials

# 4. Run locally
python -m jira_mcp --transport stdio -v
```

### Test with MCP Inspector

```bash
npx @modelcontextprotocol/inspector python -m jira_mcp
```

## 📋 Development Phases

### Phase 1: Backend (4 weeks) ← **YOU ARE HERE**

Build the generic foundation + Jira implementation:

**Week 1: Foundation Layer** (Generic & Reusable)
- ✅ BaseAgent, Persona, AgentResponse
- ✅ MCPClientManager (connect to multiple MCP servers)
- ✅ ToolRegistry (discover and filter tools)
- ✅ Permission system

**Week 2: Jira MCP Server**
- ✅ 12 Jira tools (search, CRUD, sprints, etc.)
- ✅ Deployed to Azure Container Apps
- ✅ Integrated with foundation

**Week 3: Persona Agents**
- ✅ General User Agent (limited permissions)
- ✅ Admin Agent (full access)
- ✅ Permission enforcement

**Week 4: Orchestrator**
- ✅ Route to appropriate persona agent
- ✅ FastAPI backend
- ✅ `/execute` and `/personas` endpoints

**Deliverable**: Backend API that can be reused for ANY use case

**See**: [AGENT_IMPLEMENTATION_PLAN.md](AGENT_IMPLEMENTATION_PLAN.md) ⭐ **START HERE**

### Phase 2: Frontend (3 weeks) - FUTURE

Build persona-aware chat UI:
- **Week 5**: Persona selector + Next.js setup
- **Week 6**: Chat interface with LLM
- **Week 7**: Polish and deploy

**Deliverable**: Chat UI that works with any persona/use case

**See**: [AGENT_ARCHITECTURE.md](AGENT_ARCHITECTURE.md) for frontend design

## 🏗️ Architecture

### 5-Layer Agent-Centric Design

```
Layer 5: Frontend (Persona-Aware UI)
   ↓
Layer 4: Orchestrator (Routes to persona agents)
   ↓
Layer 3: Persona Agents (General User | Admin)
   ↓
Layer 2: MCP Servers (Jira | Graph | Azure AI)
   ↓
Layer 1: Foundation (Generic & Reusable)
```

**See**: [AGENT_ARCHITECTURE.md](AGENT_ARCHITECTURE.md) for detailed architecture

### Example: General User vs Admin

```python
# General User - Limited permissions
general_user_persona = Persona(
    name="general_user",
    permissions=[
        Permission("jira", "read", "*"),      # Read all
        Permission("jira", "write", "own"),   # Write own only
    ],
    allowed_tools=[
        "jira_search",
        "jira_get_issue",
        "jira_create_issue",
        "jira_update_issue",  # Filtered to own issues
    ]
)

# Admin - Full permissions
admin_persona = Persona(
    name="admin",
    permissions=[
        Permission("jira", "*", "*"),  # All permissions
    ],
    allowed_tools=[
        "jira_search",
        "jira_delete_issue",
        "jira_create_sprint",
        "jira_bulk_update",
        # ... all tools
    ]
)
```

## 🔑 Authentication

Supports multiple authentication methods:

### Priority 1: Per-Request Token
```bash
# OAuth (Cloud)
curl -H "Authorization: Bearer <oauth_token>" \
     https://jira-mcp-server.azurecontainerapps.io/mcp

# PAT (Server/DC)
curl -H "Authorization: Token <pat>" \
     https://jira-mcp-server.azurecontainerapps.io/mcp
```

### Priority 2: Server-Level Config
```bash
# Environment variables
JIRA_URL=https://your-domain.atlassian.net
JIRA_USERNAME=sa.jira.mscopilot.uat@ifs.com
JIRA_API_TOKEN=<your_token>
```

### Priority 3: Azure AD (Future)
```bash
AZURE_CLIENT_ID=<client_id>
AZURE_TENANT_ID=<tenant_id>
AZURE_USE_MANAGED_IDENTITY=true
```

## 🛠️ Tools (Phase 1)

### Core Tools (Priority 0)
- `jira_search` - Search issues using JQL
- `jira_get_issue` - Get issue details
- `jira_create_issue` - Create new issue
- `jira_update_issue` - Update existing issue
- `jira_add_comment` - Add comment to issue
- `jira_transition_issue` - Change issue status

### Advanced Tools (Priority 1 - Future)
- Sprint/board management
- Worklog tracking
- Issue linking
- Batch operations

## 🧪 Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src/jira_mcp --cov-report=html

# Run integration tests
pytest tests/integration/ -v
```

## 🚢 Deployment

### Docker

```bash
# Build
docker build -t jira-mcp-server:latest .

# Run locally
docker run --env-file .env -p 8000:8000 jira-mcp-server:latest

# Health check
curl http://localhost:8000/healthz
```

### Azure Container Apps

```bash
# Build and push to ACR
az acr login --name <acr-name>
docker tag jira-mcp-server:latest <acr-name>.azurecr.io/jira-mcp-server:latest
docker push <acr-name>.azurecr.io/jira-mcp-server:latest

# Deploy
az containerapp create \
  --name jira-mcp-server \
  --resource-group jira-mcp-rg \
  --environment jira-mcp-env \
  --image <acr-name>.azurecr.io/jira-mcp-server:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5
```

See [PHASE1_IMPLEMENTATION.md](PHASE1_IMPLEMENTATION.md) Week 5 for complete deployment guide.

## 🤖 Microsoft Agent Framework Integration

### Python Agent

```python
from mcp.client.streamable_http import streamablehttp_client
from mcp import ClientSession

async with streamablehttp_client(
    "https://jira-mcp-server.azurecontainerapps.io/mcp",
    headers={"Authorization": f"Bearer {token}"}
) as (read, write, _):
    async with ClientSession(read, write) as session:
        await session.initialize()
        result = await session.call_tool(
            "jira_search",
            {"jql": "project = JB AND status = Open"}
        )
```

### .NET Agent

```csharp
using Microsoft.Agents.AI;
using Microsoft.Agents.MCP;

var agent = new Agent("JiraAgent")
    .WithMCPServer("https://jira-mcp-server.azurecontainerapps.io/mcp")
    .WithAzureAD();

var result = await agent.RunAsync("Find all P0 bugs in project JB");
```

## 🎓 Why This Architecture?

### Reusability
Each layer is independent and reusable:
- Foundation works for **any** use case (HR, support, sales, etc.)
- MCP servers are composable services
- Personas apply to any domain
- Frontend works with any agents

### Example: Add HR Use Case

To add HR onboarding, just add:
1. **HR MCP Server** - Employee DB, benefits tools
2. **Personas**: New Employee, HR Admin
3. **Agents**: NewEmployeeAgent, HRAdminAgent
4. **Done** - Same foundation, same frontend

### Security
- Permissions enforced at agent layer
- Tools filtered per persona
- JQL auto-filtered for scope
- Azure AD authentication
- Full audit trail

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **README.md** | This file - project overview |
| **[AGENT_ARCHITECTURE.md](AGENT_ARCHITECTURE.md)** | **Agent-centric architecture** - Read this first! |
| **[AGENT_IMPLEMENTATION_PLAN.md](AGENT_IMPLEMENTATION_PLAN.md)** | ⭐ **START CODING HERE** - Week-by-week guide |
| **[PHASED_APPROACH.md](PHASED_APPROACH.md)** | Original two-phase approach |
| **[PHASE1_IMPLEMENTATION.md](PHASE1_IMPLEMENTATION.md)** | Original MCP server plan |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Original hybrid architecture |
| **[CLAUDE.md](CLAUDE.md)** | Development guide for Claude Code |

## 🎓 Reference Implementations

This project leverages proven patterns from:
- **[mcp-atlassian](https://github.com/sooperset/mcp-atlassian)** (3.6k ⭐) - Jira integration patterns
  - Cloned to `/tmp/mcp-atlassian` for reference
- **[FastMCP 2.0](https://gofastmcp.com/)** - Modern MCP framework
- **[Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/)** - Agentic AI

## 🏃 Getting Started

### 🎯 Start Here: Week 1 - Foundation Layer

Build the **generic, reusable foundation** that works for ANY use case:

**Day 1-2**: Project structure + Persona system
```bash
mkdir -p src/{foundation,agents,orchestration,mcp_servers}
# Create BaseAgent, Persona, Permission classes
```

**Day 2-3**: Agent framework
```bash
# Create BaseAgent with execute() method
# Create AgentResponse standardized format
```

**Day 3-4**: MCP Client Manager
```bash
# MCPClientManager - connect to multiple MCP servers
# ToolRegistry - discover and filter tools
```

**Day 4-5**: Permission system
```bash
# PermissionChecker - validate tool usage
# JQL filtering for personas
```

**Follow**: [AGENT_IMPLEMENTATION_PLAN.md](AGENT_IMPLEMENTATION_PLAN.md) ⭐ **START CODING HERE**

### Key Files (Week 1)
```
src/foundation/
├── agents/
│   ├── base_agent.py        # BaseAgent abstract class
│   ├── persona.py           # Persona + Permission
│   └── agent_response.py    # Standardized response
├── mcp/
│   ├── client_manager.py    # MCPClientManager
│   └── tool_registry.py     # ToolRegistry
└── auth/
    └── permission_checker.py
```

## 🤝 Contributing

This is a **platform**, not just a Jira tool. Contributions should maintain the generic, reusable nature of the foundation layer.

## 📝 License

[Add your license here]

## 🙋 Support

For questions:
- **Architecture**: See [AGENT_ARCHITECTURE.md](AGENT_ARCHITECTURE.md)
- **Implementation**: See [AGENT_IMPLEMENTATION_PLAN.md](AGENT_IMPLEMENTATION_PLAN.md)
- **Personas & Use Cases**: See examples in documentation

---

---

## 🎯 Ready to Start?

### 👉 **[START HERE: Complete Organization Guide](START_HERE.md)** 👈

The START_HERE.md document provides:
- Complete reading order for all documentation
- Pre-flight checklist for tomorrow
- Quick decision tree
- Success metrics
- Cursor prompt template

**Everything is organized and ready for you to start building tomorrow!**

### Quick Links

- **[START_HERE.md](START_HERE.md)** - Read this first! Complete organization guide
- **[MASTER_PLAN.md](MASTER_PLAN.md)** - Your source of truth for 7-week plan
- **[AGENT_ARCHITECTURE.md](AGENT_ARCHITECTURE.md)** - Complete architecture
- **[AGENT_IMPLEMENTATION_PLAN.md](AGENT_IMPLEMENTATION_PLAN.md)** - Daily implementation guide
- **[PRE_FLIGHT_CHECKLIST.md](PRE_FLIGHT_CHECKLIST.md)** - Complete this today!

---

**Good luck building the platform! 🚀**
