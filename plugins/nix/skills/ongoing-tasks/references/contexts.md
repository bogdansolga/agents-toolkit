# Work Contexts: Clients and Internal

Every N-iX task belongs to one or more of two contexts: clients and internal. Every engagement is also placed on the AI Delivery Model, which says what kind of work it implies. Use this file; don't re-read the deck.

## The AI Delivery Model (Source: GVL Services Deck, S3)

Deck: `1WfI1X3E7saYABhOC0ivQE2xOIS-OUuTBz-P4K5za4vw`. This is the N-iX reference model for AI-enabled delivery, across process, people, tools, governance and evidence.

| Level | Name | What delivery looks like | AI usage unit |
|---|---|---|---|
| L5 | AI Native | Agents run workflows end to end; people step in on exceptions. Defined, not offered. | - |
| L4 | AI Driven | AI drives the life cycle; people set intent and approve at gates. The N-iX ceiling today. | work units (Jira items) |
| L3 | AI Assisted | AI on selected tasks; planning and review stay human. | small tasks |
| L2 | AI Supported | Individuals use AI on their own tasks; the process does not. Most teams today. | the person |
| L1 | Traditional | No AI in the delivery path; knowledge lives in people's heads. | none |

- **Pillars:** Process · People · Tools, sustained by Governance and Metrics.
- **Evidence:** a baseline before and a measurement after, with the APEX Core4 metrics: AI Adoption · Throughput · Quality · Speed.
- **The three questions the model answers:** Where is the team today? What does delivery look like at that level? What has to change to move up?

## Engagement Types: The Two Top-Level Domains

Place every engagement (client or internal) in one of these two. The type of work follows from it.

| Domain | Move | The work |
|---|---|---|
| **APEX Acceleration** | L1/L2 → L3 | Champion-led and bottom-up; about three months. L3 is a legitimate end state for many teams. Typical work: AI tool rollout and training (Copilot, Claude Code), adoption assessment, champions, baseline metrics. |
| **APEX Transformation** | L3 → L4 | AI-DLC as the daily process, plus the harness that keeps agents inside it. Programs start from 3 months, adapted to the project. Typical work: AI-DLC rollout, the agentic harness, Agentic Kit agents, governance, a context layer. |

Examples: PrivatBank Copilot training and Zempler's Claude Code assessment are Acceleration; the UTA context layer is Transformation.

## Services Within Both Domains

These serve either domain; a task names the service next to its domain.

| Service | Covers |
|---|---|
| `delivery-model` | The model itself, AI-DLC, enablement and training decks (Superpowers, Copilot) |
| `aws-funding` | AWS funding for the Assess and Pilot phases: AI Assessment, PoC, GenAI SCA, MAP, BVR; data readiness (FORGE) |
| `agentic-kit` | The Agentic Kit platform, the APEX Agent Suite (incl. FinOps and Security agents), the Sandbox |
| `ai-governance` | AI Governance, the Core4 metrics, DevEx platforms (DX, Swarmia, WorkWeave), attribution (Git AI) |

The service list is a first draft and will be refined with the user. Update this file when it changes.

## Clients

`clients/<presales|upsales>/<active|inactive>/<Client>/0N-<slug>/`

- **presales:** a new client; the work is a proposal, an assessment plan or a pitch (UTA, Zempler).
- **upsales:** an existing N-iX client; the work extends the engagement (PrivatBank, AbbVie, AzerCell, Ringier).
- **active / inactive:** almost all task work is under `active/`. The user moves client folders between them, never the skill.
- `<Client>` is the client's real name with no spaces (`BostonScientific`, `RedBull`). A client folder can be a git repo.
- Client tasks usually reuse an internal asset (the Copilot training, AWS funding); link it in `task.md`, don't copy it.

## Internal

`internal/0N-<slug>/`: tasks that build N-iX assets, each serving one service above.

**Proposed layout, not applied:** `internal/<service>/0N-<slug>/`. It would move 04 and 07 to `aws-funding/` and 06 to `delivery-model/`. Apply it only on the user's yes; a move also means updating the index, the Claude history keys and every hub-relative path.

## Recording It

Each `task.md` carries an **Engagement** line, for example `Acceleration (L2 → L3) · service: delivery-model`. Use `-` for a part that doesn't apply, for example an internal asset that serves both domains.
