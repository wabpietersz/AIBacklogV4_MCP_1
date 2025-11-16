# Agent-Centric Architecture

## Vision

Build a **generic, reusable agentic platform** where:
- Solutions are composable and reusable
- Agents orchestrate based on requirements
- Personas define capabilities and permissions
- MCP servers provide specialized tools
- Frontend is agent-agnostic

**First Use Case**: Jira project management with General User and Admin personas

---

## Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Layer 5: Frontend (UI)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │           Chat Interface (Persona-Aware)                  │  │
│  │  - User selects persona (General User / Admin)            │  │
│  │  - Natural language input                                 │  │
│  │  - Conversational history per persona                     │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│            Layer 4: Orchestration (Agent Router)                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Orchestrator Agent                           │  │
│  │  - Analyzes user intent                                   │  │
│  │  - Routes to appropriate persona agent                    │  │
│  │  - Handles multi-step workflows                           │  │
│  │  - Aggregates results from multiple agents                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐
│  Layer 3: Persona Agents    │   │  Layer 3: Persona Agents    │
│ ┌─────────────────────────┐ │   │ ┌─────────────────────────┐ │
│ │  General User Agent     │ │   │ │    Admin Agent          │ │
│ │  - Limited permissions  │ │   │ │  - Full permissions     │ │
│ │  - Read/search Jira     │ │   │ │  - All Jira operations  │ │
│ │  - Create basic issues  │ │   │ │  - Project management   │ │
│ │  - Add comments         │ │   │ │  - User management      │ │
│ │  - Self-assigned tasks  │ │   │ │  - Settings & config    │ │
│ └─────────────────────────┘ │   │ └─────────────────────────┘ │
└─────────────────────────────┘   └─────────────────────────────┘
            │                                   │
            └─────────────────┬─────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│               Layer 2: MCP Servers (Tools)                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │  Jira MCP Server │  │  Graph MCP       │  │  Azure AI     │ │
│  │  - Search        │  │  - Teams         │  │  - Search     │ │
│  │  - CRUD issues   │  │  - Calendar      │  │  - Cognitive  │ │
│  │  - Workflows     │  │  - Users         │  │  - OpenAI     │ │
│  │  - Sprints       │  │  - Groups        │  │               │ │
│  └──────────────────┘  └──────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│          Layer 1: Foundation (Generic Components)               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  - Agent Framework (base classes)                         │  │
│  │  - MCP Client abstraction                                 │  │
│  │  - Persona management                                     │  │
│  │  - Tool registry                                          │  │
│  │  - Authentication & authorization                         │  │
│  │  - Logging & observability                                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### Layer 1: Foundation (Generic & Reusable)

**Purpose**: Reusable components for any agentic solution

```python
# Generic base classes
class BaseAgent(ABC):
    """Base class for all agents."""
    def __init__(self, name: str, persona: Persona, llm: LLM):
        self.name = name
        self.persona = persona
        self.llm = llm
        self.tools = []

    @abstractmethod
    async def execute(self, task: str) -> AgentResponse:
        """Execute a task."""
        pass

class Persona:
    """Defines capabilities and permissions."""
    def __init__(self, name: str, permissions: list[str], tools: list[str]):
        self.name = name
        self.permissions = permissions  # e.g., ["jira:read", "jira:create_issue"]
        self.allowed_tools = tools      # e.g., ["jira_search", "jira_create_issue"]

class MCPClientManager:
    """Manages connections to multiple MCP servers."""
    def __init__(self):
        self.servers = {}

    async def register_server(self, name: str, url: str, auth: dict):
        """Register an MCP server."""
        pass

    async def call_tool(self, server: str, tool: str, params: dict):
        """Call a tool on an MCP server."""
        pass

class ToolRegistry:
    """Registry of all available tools across MCP servers."""
    def __init__(self):
        self.tools = {}

    def register_from_mcp(self, server_name: str, tools: list[Tool]):
        """Register tools from an MCP server."""
        pass

    def get_tools_for_persona(self, persona: Persona) -> list[Tool]:
        """Get tools available to a persona."""
        return [t for t in self.tools.values() if t.name in persona.allowed_tools]
```

**Files**:
```
src/foundation/
├── __init__.py
├── agents/
│   ├── base_agent.py          # BaseAgent abstract class
│   ├── persona.py             # Persona definition
│   └── agent_response.py      # Standardized response format
├── mcp/
│   ├── client_manager.py      # MCPClientManager
│   ├── tool_registry.py       # ToolRegistry
│   └── mcp_config.py          # MCP server configurations
├── auth/
│   ├── auth_provider.py       # Abstract auth provider
│   ├── azure_ad_auth.py       # Azure AD implementation
│   └── permission_checker.py  # Check if persona can use tool
└── utils/
    ├── logging.py
    └── telemetry.py
```

### Layer 2: MCP Servers (Specialized Tools)

**Purpose**: Domain-specific tools as MCP servers

Each MCP server is independent and reusable:
- **Jira MCP Server** - Jira operations
- **Microsoft Graph MCP** - Teams, Calendar, Users (future)
- **Azure AI MCP** - OpenAI, Search, Cognitive Services (future)

**Implementation**: As planned in PHASE1_IMPLEMENTATION.md

### Layer 3: Persona Agents (Use Case Specific)

**Purpose**: Persona-specific agents with limited tools and capabilities

#### General User Agent

```python
class GeneralUserAgent(BaseAgent):
    """Agent for general users with limited Jira permissions."""

    def __init__(self, llm: LLM, mcp_manager: MCPClientManager):
        persona = Persona(
            name="general_user",
            permissions=[
                "jira:read",
                "jira:search",
                "jira:create_issue",
                "jira:comment",
                "jira:update_own_issues"
            ],
            tools=[
                "jira_search",
                "jira_get_issue",
                "jira_create_issue",
                "jira_add_comment",
                "jira_update_issue",  # Limited to own issues
            ]
        )
        super().__init__("GeneralUserAgent", persona, llm)
        self.mcp_manager = mcp_manager

    async def execute(self, task: str, user_context: dict) -> AgentResponse:
        """Execute task with general user permissions."""
        # LLM decides which tools to use
        # Only allows tools in persona.allowed_tools
        # Adds JQL filters for "assignee = currentUser()" automatically
        pass

    def _enhance_jql_for_user(self, jql: str, user_email: str) -> str:
        """Add user restrictions to JQL."""
        # For update operations, ensure user can only update their own issues
        return f"({jql}) AND assignee = {user_email}"
```

**Capabilities**:
- Search issues (all visible issues in project)
- View issue details
- Create new issues (Bug, Task, Story)
- Add comments to any issue
- Update own assigned issues only
- View sprint/board (read-only)

#### Admin Agent

```python
class AdminAgent(BaseAgent):
    """Agent for admins with full Jira permissions."""

    def __init__(self, llm: LLM, mcp_manager: MCPClientManager):
        persona = Persona(
            name="admin",
            permissions=[
                "jira:*",  # All permissions
                "jira:admin"
            ],
            tools=[
                # All Jira tools
                "jira_search",
                "jira_get_issue",
                "jira_create_issue",
                "jira_update_issue",
                "jira_delete_issue",
                "jira_add_comment",
                "jira_transition_issue",
                "jira_create_sprint",
                "jira_update_sprint",
                "jira_manage_users",
                "jira_project_settings",
                "jira_workflow_management",
                "jira_batch_operations",
            ]
        )
        super().__init__("AdminAgent", persona, llm)
        self.mcp_manager = mcp_manager

    async def execute(self, task: str, user_context: dict) -> AgentResponse:
        """Execute task with admin permissions."""
        # Full access to all tools
        # No JQL restrictions
        # Can perform batch operations
        # Can manage project settings
        pass
```

**Capabilities**:
- Everything General User can do, plus:
- Update any issue (not just own)
- Delete issues
- Transition any issue
- Create/update sprints
- Manage project settings
- Manage users and permissions
- Workflow configuration
- Batch operations

**Files**:
```
src/agents/
├── __init__.py
├── jira/
│   ├── general_user_agent.py
│   ├── admin_agent.py
│   └── persona_configs.py    # Persona definitions
└── base/
    └── llm_agent.py           # LLM integration base
```

### Layer 4: Orchestration (Agent Router)

**Purpose**: Route requests to appropriate persona agents

```python
class OrchestratorAgent(BaseAgent):
    """Meta-agent that routes to persona agents."""

    def __init__(self, llm: LLM):
        super().__init__("Orchestrator", None, llm)
        self.persona_agents = {}

    def register_agent(self, persona_name: str, agent: BaseAgent):
        """Register a persona agent."""
        self.persona_agents[persona_name] = agent

    async def execute(self, task: str, user_context: dict) -> AgentResponse:
        """Route to appropriate persona agent."""
        persona = user_context.get("persona", "general_user")

        # Get the appropriate agent
        agent = self.persona_agents.get(persona)
        if not agent:
            return AgentResponse(error=f"Unknown persona: {persona}")

        # Delegate to persona agent
        return await agent.execute(task, user_context)

    async def multi_agent_workflow(self, workflow: Workflow) -> WorkflowResponse:
        """Execute multi-step workflow across multiple agents."""
        # For complex tasks requiring multiple personas
        # Example: General user creates issue, admin assigns and prioritizes
        pass
```

**Advanced Features** (Future):
- Analyze task complexity and route to multiple agents
- Coordinate multi-step workflows
- Aggregate results from multiple agents
- Handle agent-to-agent communication (A2A protocol)

**Files**:
```
src/orchestration/
├── __init__.py
├── orchestrator.py         # OrchestratorAgent
├── router.py               # Request routing logic
└── workflow_engine.py      # Multi-agent workflows
```

### Layer 5: Frontend (Chat UI)

**Purpose**: Persona-aware chat interface

**Key Features**:
1. **Persona Selector**
   - User chooses: General User or Admin
   - Different UI hints based on persona
   - Separate conversation history per persona

2. **Persona-Aware Chat**
   - Shows available capabilities
   - Suggests common tasks for persona
   - Displays tool usage in real-time

3. **Contextual Help**
   - "As General User, you can..."
   - "Switch to Admin to..."

**UI Design**:
```
┌──────────────────────────────────────────────────────────────┐
│  Jira Assistant                        [@] Admin   [Settings] │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  [🔵 General User] [🔴 Admin]  ← Persona selector             │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Chat History                                            │ │
│  │                                                         │ │
│  │ You: Show me all open bugs                             │ │
│  │                                                         │ │
│  │ Agent (General User): 🔍 Searching Jira...             │ │
│  │ Found 12 open bugs in project JB:                      │ │
│  │ • JB-123: Login fails on Safari                        │ │
│  │ • JB-124: API timeout on large requests               │ │
│  │ ...                                                    │ │
│  │                                                         │ │
│  │ You: Assign JB-123 to me                               │ │
│  │                                                         │ │
│  │ Agent: ⚠️ As General User, you can't assign issues.    │ │
│  │ Would you like to switch to Admin persona?            │ │
│  │                                                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                                │
│  💡 Suggestions (General User):                               │
│     • "Show my assigned issues"                               │
│     • "Create a new bug"                                      │
│     • "What's in the current sprint?"                         │
│                                                                │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Type your message...                           [Send] │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

---

## Revised Implementation Plan

### Phase 1: Foundation + Jira MCP Server (4 weeks)

#### Week 1: Foundation Layer
- [ ] Generic agent framework (`BaseAgent`, `Persona`)
- [ ] `MCPClientManager` for connecting to MCP servers
- [ ] `ToolRegistry` for tool discovery
- [ ] Permission system (`PermissionChecker`)

#### Week 2: Jira MCP Server
- [ ] Build Jira MCP server (as in PHASE1_IMPLEMENTATION.md)
- [ ] 6 core tools + 6 advanced tools
- [ ] Register with `MCPClientManager`

#### Week 3: Persona Agents
- [ ] `GeneralUserAgent` with limited permissions
- [ ] `AdminAgent` with full permissions
- [ ] Persona configuration system
- [ ] Tool filtering per persona

#### Week 4: Orchestrator
- [ ] `OrchestratorAgent` for routing
- [ ] Persona-based routing logic
- [ ] Basic workflow engine
- [ ] Testing with both personas

**Deliverable**: Backend API that accepts persona + task

### Phase 2: Frontend (3 weeks)

#### Week 5: Next.js Setup + Persona UI
- [ ] Next.js project setup
- [ ] Persona selector component
- [ ] Separate chat contexts per persona
- [ ] Azure AD authentication

#### Week 6: Chat Interface
- [ ] Chat UI with streaming responses
- [ ] Tool execution visualization
- [ ] Persona-aware suggestions
- [ ] Error handling (permission denied)

#### Week 7: Polish & Deploy
- [ ] Direct Jira operations UI (optional)
- [ ] Admin dashboard
- [ ] Deploy to Azure
- [ ] End-to-end testing

**Deliverable**: Full chat UI with persona switching

---

## Example User Flows

### General User Flow

```
User: "Show me my assigned bugs"
  ↓
Orchestrator → GeneralUserAgent
  ↓
GeneralUserAgent:
  1. Constructs JQL: "project = JB AND assignee = currentUser() AND type = Bug"
  2. Calls jira_search via MCP
  3. Returns formatted results
  ↓
User sees: 3 bugs assigned to them

User: "Create a new bug for the login issue"
  ↓
GeneralUserAgent:
  1. Calls jira_create_issue
  2. Sets reporter = currentUser
  ↓
Issue JB-456 created

User: "Assign JB-123 to John"
  ↓
GeneralUserAgent:
  1. Checks permissions
  2. User can't assign (not admin)
  3. Returns error with suggestion
  ↓
User sees: "You need Admin permissions. Switch persona?"
```

### Admin Flow

```
User: (Switches to Admin persona)

User: "Assign JB-123 to John and set priority to High"
  ↓
Orchestrator → AdminAgent
  ↓
AdminAgent:
  1. Calls jira_update_issue (assignee)
  2. Calls jira_update_issue (priority)
  3. Both succeed (admin has permissions)
  ↓
Issue updated successfully

User: "Create a new sprint for next week and add all P0 bugs to it"
  ↓
AdminAgent:
  1. Calls jira_create_sprint
  2. Calls jira_search (priority = P0, type = Bug)
  3. Calls jira_add_issues_to_sprint (batch)
  ↓
Sprint created with 8 P0 bugs
```

---

## Extensibility: Adding New Use Cases

Because the foundation is generic, adding new use cases is straightforward:

### Example: HR Onboarding Use Case

1. **MCP Server**: Build HR MCP server (employee DB, benefits, equipment)
2. **Personas**:
   - **New Employee**: Limited to viewing own info, requesting equipment
   - **HR Admin**: Full access to all employee data
3. **Agents**: `NewEmployeeAgent`, `HRAdminAgent`
4. **Frontend**: Same chat UI, different persona selector

### Example: Customer Support Use Case

1. **MCP Servers**: Ticketing system, knowledge base, CRM
2. **Personas**:
   - **L1 Support**: Basic ticket operations
   - **L2 Support**: Advanced troubleshooting
   - **Manager**: Analytics, SLA management
3. **Agents**: `L1Agent`, `L2Agent`, `ManagerAgent`
4. **Orchestrator**: Routes based on ticket complexity

---

## Technology Stack (Updated)

### Foundation Layer
- **Language**: Python 3.10+
- **Agent Framework**: Microsoft Agent Framework (Python SDK)
- **MCP SDK**: `mcp` Python package
- **LLM**: Azure OpenAI (GPT-4o)
- **Auth**: Azure AD / Entra ID

### MCP Servers
- **Framework**: FastMCP 2.0
- **Protocol**: MCP (stdio, SSE, streamable-http)
- **Hosting**: Azure Container Apps

### Frontend
- **Framework**: Next.js 15 (App Router)
- **UI**: React 18 + Tailwind + shadcn/ui
- **LLM Client**: Vercel AI SDK
- **Auth**: NextAuth.js with Azure AD
- **Hosting**: Azure Static Web Apps

---

## Benefits of This Architecture

### Reusability
- Foundation layer works for any use case
- MCP servers are independent and composable
- Persona pattern applies to any domain

### Scalability
- Add new MCP servers without changing foundation
- Add new personas without changing infrastructure
- Add new use cases by composing existing components

### Security
- Persona-based permissions enforced at agent layer
- Tools filtered per persona
- Azure AD for authentication
- Audit trail of all agent actions

### Maintainability
- Clear separation of concerns
- Each layer independently testable
- Generic components reduce code duplication

---

## Next Steps

1. **Review this architecture** - Does it align with your vision?
2. **Start Phase 1, Week 1** - Build foundation layer
3. **Build Jira MCP Server** - Using patterns from mcp-atlassian
4. **Implement persona agents** - General User and Admin
5. **Build orchestrator** - Route to persona agents
6. **Create frontend** - Persona-aware chat UI

This architecture sets you up for a **platform**, not just a Jira tool. Every component is designed for reuse across multiple use cases.
