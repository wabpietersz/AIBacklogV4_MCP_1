# Two-Phase Development Approach

## Overview

This project will be built in two distinct phases:

1. **Phase 1**: Jira MCP Server (Backend) - Build and deploy the core MCP server
2. **Phase 2**: Frontend Interface - Create a web UI to interact with the MCP server

---

## Phase 1: Jira MCP Server (Weeks 1-5)

### Objective
Build a production-ready Jira MCP server that can be consumed by:
- Microsoft Agent Framework
- Claude Desktop
- Cursor IDE
- Any MCP-compatible client
- **Our custom frontend (Phase 2)**

### Deliverables

#### Week 1-2: Core MCP Server
- [ ] Project setup and configuration system
- [ ] FastMCP 2.0 server with custom `JiraMCP` class
- [ ] Jira API client (port from mcp-atlassian)
- [ ] Basic authentication (PAT, API token)
- [ ] Core 6 tools (P0):
  - `jira_search` (JQL)
  - `jira_get_issue`
  - `jira_create_issue`
  - `jira_update_issue`
  - `jira_add_comment`
  - `jira_transition_issue`

#### Week 2-3: Authentication & Advanced Features
- [ ] User token middleware (multi-tenant)
- [ ] Azure AD / Entra ID integration
- [ ] OAuth 2.0 support
- [ ] Advanced tools (P1):
  - Sprint/board management
  - Worklog tracking
  - Issue linking
- [ ] Tool filtering and access control

#### Week 3-4: Testing
- [ ] Unit tests (80%+ coverage)
- [ ] Integration tests with real Jira instance
- [ ] MCP protocol compliance tests
- [ ] Load testing (100 req/min)

#### Week 4-5: Deployment
- [ ] Docker containerization
- [ ] Azure Container Registry setup
- [ ] Azure Container Apps deployment
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Monitoring (Application Insights)
- [ ] Health checks and auto-scaling

### Success Criteria for Phase 1
- ✅ All 6 core tools working correctly
- ✅ Multi-auth working (PAT, OAuth, Azure AD)
- ✅ Deployed to Azure Container Apps
- ✅ Public endpoint accessible: `https://jira-mcp-dev.azurecontainerapps.io/mcp`
- ✅ Health endpoint responding: `/healthz`
- ✅ 80%+ test coverage
- ✅ Sub-500ms p95 latency
- ✅ Documentation complete

### Testing Phase 1 Without Frontend

Before building the frontend, test the MCP server with:

1. **MCP Inspector** (official testing tool):
```bash
npx @modelcontextprotocol/inspector python -m jira_mcp
```

2. **Microsoft Agent Framework** (Python):
```python
from mcp.client.streamable_http import streamablehttp_client
from mcp import ClientSession

async with streamablehttp_client(
    "https://jira-mcp-dev.azurecontainerapps.io/mcp"
) as (read, write, _):
    async with ClientSession(read, write) as session:
        await session.initialize()
        tools = await session.list_tools()
        result = await session.call_tool("jira_search", {"jql": "project = JB"})
```

3. **Claude Desktop** (config):
```json
{
  "mcpServers": {
    "jira-mcp": {
      "url": "https://jira-mcp-dev.azurecontainerapps.io/mcp",
      "headers": {
        "Authorization": "Bearer <token>"
      }
    }
  }
}
```

4. **cURL** (direct HTTP testing):
```bash
# Initialize session
curl -X POST https://jira-mcp-dev.azurecontainerapps.io/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}'

# Call tool
curl -X POST https://jira-mcp-dev.azurecontainerapps.io/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"jira_search","arguments":{"jql":"project=JB"}},"id":2}'
```

---

## Phase 2: Frontend Interface (Weeks 6-9)

### Objective
Build a modern web application that provides:
- User-friendly interface to interact with Jira via MCP
- Chat-like experience for natural language Jira operations
- Admin dashboard for MCP server management
- Authentication and user management

### Technology Stack Options

#### Option A: Next.js + React (Recommended)
**Best for**: Production-ready, SEO, server-side rendering

```
Tech Stack:
- Next.js 15 (App Router)
- React 18
- TypeScript
- Tailwind CSS
- Shadcn/ui components
- Vercel AI SDK (for LLM chat)
- MCP Client SDK
```

**Pros**:
- Full-stack framework (API routes + frontend)
- Built-in authentication (NextAuth.js)
- Azure AD integration
- Fast development with shadcn/ui
- Deploy to Azure Static Web Apps or Vercel

#### Option B: React SPA + FastAPI Backend
**Best for**: Separation of concerns, Python consistency

```
Tech Stack:
- React 18 + Vite
- TypeScript
- Tailwind CSS
- FastAPI (separate backend)
- MCP Client in Python
```

**Pros**:
- Clean separation
- Python backend (consistent with MCP server)
- Can reuse Jira logic
- Deploy frontend to Azure Static Web Apps, backend to Container Apps

### Frontend Architecture (Option A - Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│                    Next.js Frontend                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Chat Interface                           │  │
│  │  - Natural language input                             │  │
│  │  - LLM interprets and calls MCP tools                 │  │
│  │  - Display Jira results in chat                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│  ┌────────────────────────┴────────────────────────┐        │
│  │                                                  │        │
│  ▼                                                  ▼        │
│ ┌──────────────────────┐            ┌──────────────────────┐│
│ │   MCP Client Layer   │            │  Direct Jira UI      ││
│ │  - Tool execution    │            │  - Issue browser     ││
│ │  - Session mgmt      │            │  - Create forms      ││
│ │  - Auth handling     │            │  - Sprint board      ││
│ └──────────────────────┘            └──────────────────────┘│
│            │                                                 │
│            ▼                                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │         MCP Server (Phase 1)                            │ │
│ │   https://jira-mcp-dev.azurecontainerapps.io/mcp        │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Features (Phase 2)

#### Core Features (Week 6-7)

1. **Authentication**
   - Azure AD / Entra ID login
   - JWT token management
   - Pass-through to MCP server

2. **Chat Interface**
   - Natural language input
   - LLM integration (GPT-4o via Azure OpenAI)
   - Stream responses
   - Tool execution visualization
   - Chat history

3. **Direct Jira Operations**
   - Search issues (JQL builder with autocomplete)
   - View issue details
   - Create new issues (smart forms)
   - Update issues
   - Add comments
   - Transition issues

#### Advanced Features (Week 7-8)

4. **Dashboard**
   - My assigned issues
   - Recent activity
   - Sprint overview
   - Quick actions

5. **Admin Panel**
   - MCP server health status
   - Tool availability
   - Usage metrics
   - User management

6. **Advanced Jira Views**
   - Kanban board
   - Sprint planning view
   - Worklog/time tracking
   - Issue relationships graph

#### Polish (Week 8-9)

7. **User Experience**
   - Dark/light mode
   - Keyboard shortcuts
   - Offline support (PWA)
   - Mobile responsive

8. **Performance**
   - Optimistic UI updates
   - Request caching
   - Infinite scroll for search
   - Real-time updates (webhooks)

### Project Structure (Frontend)

```
jira-mcp-frontend/
├── src/
│   ├── app/                    # Next.js 15 App Router
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   └── callback/
│   │   ├── (dashboard)/
│   │   │   ├── chat/           # Chat interface
│   │   │   ├── issues/         # Issue browser
│   │   │   ├── create/         # Create issue
│   │   │   └── admin/          # Admin panel
│   │   ├── api/                # API routes
│   │   │   ├── mcp/            # MCP client proxy
│   │   │   └── auth/           # Auth endpoints
│   │   └── layout.tsx
│   ├── components/
│   │   ├── chat/
│   │   │   ├── ChatInput.tsx
│   │   │   ├── ChatMessage.tsx
│   │   │   └── ToolExecution.tsx
│   │   ├── jira/
│   │   │   ├── IssueCard.tsx
│   │   │   ├── IssueForm.tsx
│   │   │   ├── KanbanBoard.tsx
│   │   │   └── SprintView.tsx
│   │   └── ui/                 # shadcn/ui components
│   ├── lib/
│   │   ├── mcp-client.ts       # MCP client wrapper
│   │   ├── llm.ts              # LLM integration
│   │   └── auth.ts             # Auth utilities
│   └── types/
│       ├── mcp.ts
│       └── jira.ts
├── public/
├── package.json
├── next.config.js
├── tailwind.config.js
└── tsconfig.json
```

### Key Implementation: MCP Client in Next.js

```typescript
// lib/mcp-client.ts
import { streamablehttp_client } from '@modelcontextprotocol/sdk/client/streamable-http.js';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';

export class JiraMCPClient {
  private client: Client;

  constructor(private serverUrl: string, private authToken: string) {}

  async connect() {
    const { readStream, writeStream } = await streamablehttp_client(
      this.serverUrl,
      {
        headers: {
          'Authorization': `Bearer ${this.authToken}`,
          'X-Atlassian-Cloud-Id': process.env.NEXT_PUBLIC_ATLASSIAN_CLOUD_ID
        }
      }
    );

    this.client = new Client({
      name: 'jira-mcp-frontend',
      version: '1.0.0'
    }, {
      capabilities: {}
    });

    await this.client.connect(readStream, writeStream);
  }

  async searchJira(jql: string) {
    return await this.client.callTool('jira_search', { jql });
  }

  async createIssue(project: string, summary: string, type: string) {
    return await this.client.callTool('jira_create_issue', {
      project, summary, issue_type: type
    });
  }
}
```

### Key Implementation: Chat Interface with LLM

```typescript
// app/chat/page.tsx
'use client';

import { useChat } from 'ai/react';
import { JiraMCPClient } from '@/lib/mcp-client';

export default function ChatPage() {
  const { messages, input, handleInputChange, handleSubmit } = useChat({
    api: '/api/chat',  // Next.js API route
  });

  return (
    <div className="flex flex-col h-screen">
      <div className="flex-1 overflow-y-auto">
        {messages.map(m => (
          <ChatMessage key={m.id} message={m} />
        ))}
      </div>
      <form onSubmit={handleSubmit}>
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Ask me to create a Jira ticket..."
        />
      </form>
    </div>
  );
}
```

```typescript
// app/api/chat/route.ts
import { StreamingTextResponse, LangChainStream } from 'ai';
import { ChatOpenAI } from '@langchain/openai';
import { JiraMCPClient } from '@/lib/mcp-client';

export async function POST(req: Request) {
  const { messages } = await req.json();
  const { stream, handlers } = LangChainStream();

  // Initialize MCP client
  const mcpClient = new JiraMCPClient(
    process.env.MCP_SERVER_URL!,
    req.headers.get('authorization')!.split(' ')[1]
  );
  await mcpClient.connect();

  // Get available tools from MCP server
  const tools = await mcpClient.listTools();

  // Initialize LLM with MCP tools
  const llm = new ChatOpenAI({
    modelName: 'gpt-4o',
    streaming: true,
  });

  // LLM decides which tools to call based on user message
  llm.call(messages, {
    tools: tools.map(t => ({
      name: t.name,
      description: t.description,
      parameters: t.inputSchema
    })),
    callbacks: [handlers]
  });

  return new StreamingTextResponse(stream);
}
```

### Deployment (Phase 2)

#### Option 1: Azure Static Web Apps (Recommended)
```bash
# Deploy Next.js to Azure Static Web Apps
az staticwebapp create \
  --name jira-mcp-frontend \
  --resource-group ${RESOURCE_GROUP} \
  --source https://github.com/your-org/jira-mcp-frontend \
  --location "East US 2" \
  --branch main \
  --app-location "/" \
  --output-location "out"
```

Benefits:
- Free tier available
- Automatic HTTPS
- Azure AD integration built-in
- Global CDN
- API routes supported

#### Option 2: Azure Container Apps (Consistency)
- Deploy Next.js as containerized app
- Same infrastructure as MCP server
- Easier to manage both together

### Success Criteria for Phase 2
- ✅ Authentication working (Azure AD)
- ✅ Chat interface responds to natural language
- ✅ LLM correctly calls MCP tools
- ✅ All core Jira operations accessible via UI
- ✅ Mobile responsive
- ✅ Sub-200ms initial load time
- ✅ Deployed to Azure
- ✅ End-to-end testing passing

---

## Development Timeline

| Phase | Duration | Key Milestones |
|-------|----------|----------------|
| **Phase 1: MCP Server** | 5 weeks | |
| Week 1 | | Project setup, core config, basic tools |
| Week 2 | | Authentication, middleware, advanced tools |
| Week 3 | | Agile features, tool filtering |
| Week 4 | | Testing, Docker, CI/CD |
| Week 5 | | Azure deployment, monitoring, docs |
| **Phase 1 Complete** | | ✅ MCP server live in production |
| **Phase 2: Frontend** | 4 weeks | |
| Week 6 | | Next.js setup, auth, MCP client integration |
| Week 7 | | Chat interface, LLM integration, basic Jira UI |
| Week 8 | | Advanced views, dashboard, admin panel |
| Week 9 | | Polish, testing, deployment |
| **Phase 2 Complete** | | ✅ Full application live |

---

## Testing Between Phases

After Phase 1 completes, validate the MCP server with:

1. ✅ **MCP Inspector** - Verify protocol compliance
2. ✅ **Claude Desktop** - Test with production LLM client
3. ✅ **Microsoft Agent** - Validate Azure integration
4. ✅ **Postman/cURL** - HTTP endpoint testing
5. ✅ **Load testing** - 100 concurrent users

This validation ensures Phase 2 frontend will have a solid backend to build on.

---

## Advantages of Two-Phase Approach

### Technical Benefits
- **Independent testing** - MCP server can be validated before frontend work
- **Parallel development** - Different developers can work on each phase
- **Reusable backend** - MCP server can be consumed by multiple clients
- **Clear milestones** - Each phase has distinct deliverables

### Business Benefits
- **Early value** - MCP server can be used immediately with existing tools (Claude, Cursor)
- **Reduced risk** - Backend issues are caught before frontend investment
- **Flexible frontend** - Can change frontend tech stack without affecting backend
- **Microsoft Agent ready** - Phase 1 enables Microsoft Agent Framework immediately

---

## Phase 1 Priority: Focus Areas

For Phase 1, prioritize in this order:

1. **Core 6 tools working** (Week 1-2)
   - This is the MVP that proves value
   - Can test with MCP Inspector immediately

2. **Authentication** (Week 2)
   - Multi-auth support
   - Essential for production

3. **Azure deployment** (Week 4-5)
   - Public endpoint
   - Required before Phase 2

4. **Advanced tools** (Week 3)
   - Nice to have
   - Can be added after Phase 2 if needed

This ensures we have a working, deployed MCP server before starting frontend work.
