# Graph Database Africa · Neo4j

[![Live site](https://img.shields.io/badge/live-GitHub%20Pages-5EEAD4?style=flat-square)](https://thembelitchi.github.io/neo4j-graph-database-africa/) [![Licence: MIT](https://img.shields.io/badge/licence-MIT-4FB3FF?style=flat-square)](LICENSE) ![No build step](https://img.shields.io/badge/build-none%20%C2%B7%20plain%20HTML-F79767?style=flat-square)

Talks, live demos and embeddable widgets for learning knowledge graphs, Cypher, graph data science and GraphRAG, from the Neo4j community in Southern Africa.

**Live site:** https://thembelitchi.github.io/neo4j-graph-database-africa/

> Community project by Thembelihle Gumede, Neo4j Community Lead for Southern Africa. Views are my own. Neo4j® is a registered trademark of Neo4j, Inc. All demo data is fictional and for teaching only, not clinical guidance.

## Talks

Four guest lectures, each with three live widgets and a runnable Cypher script.

### The Power of the Network

An introduction to knowledge graphs and enterprise graph data science.

| Demo | What it shows | Link |
|---|---|---|
| Graph Lab | All three demos with tabs, keyboard control and the full Cypher script | [talks/power-of-the-network/](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/power-of-the-network/) |
| Cypher writer | Cypher statements type out while an antimicrobial-resistance graph builds step by step | [neo4j-cypher-writer.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/power-of-the-network/widgets/neo4j-cypher-writer.html) |
| Clinical knowledge graph | Four multi-hop questions answered across ward, lab and drug data | [neo4j-clinical-knowledge-graph.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/power-of-the-network/widgets/neo4j-clinical-knowledge-graph.html) |
| Industries explorer | Ten Neo4j case studies with headline metrics and sources | [neo4j-industries-explorer.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/power-of-the-network/widgets/neo4j-industries-explorer.html) |

### One Customer, Many Records

Enterprise master data management: graph-powered Customer 360 and real-time recommendations.

| Demo | What it shows | Link |
|---|---|---|
| Graph Lab | All three demos with tabs, keyboard control and the full Cypher script | [talks/one-customer-many-records/](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/one-customer-many-records/) |
| Identity resolution | Nine records from three systems resolve into four people, including the shared-phone trap and its guard | [identity-resolution.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/one-customer-many-records/widgets/identity-resolution.html) |
| Recommendation paths | Collaborative filtering as a walk through the graph, with popularity damping | [recommendation-paths.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/one-customer-many-records/widgets/recommendation-paths.html) |
| Customer 360 assistant | An assistant answers from the graph, shows its evidence and respects consent | [customer360-assistant.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/one-customer-many-records/widgets/customer360-assistant.html) |
| Cypher script | Runnable on Aura Free, with expected results in the comments | [customer-360-demo.cypher](talks/one-customer-many-records/customer-360-demo.cypher) |

### When One Thing Breaks

Dependency graphs (DAGs) in site reliability engineering: blast radius and cascading-failure isolation.

| Demo | What it shows | Link |
|---|---|---|
| Graph Lab | All three demos with tabs, keyboard control and the full Cypher script | [talks/when-one-thing-breaks/](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/when-one-thing-breaks/) |
| Blast radius | Fail a router and watch the outage spread hop by hop; then walk forwards to the root cause | [blast-radius.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/when-one-thing-breaks/widgets/blast-radius.html) |
| Criticality audit | Direct dependents versus transitive dependents: popular is not the same as load-bearing | [criticality.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/when-one-thing-breaks/widgets/criticality.html) |
| Deploy order | Startup waves as a topological sort, and how one synchronous callback creates a cycle | [deploy-order.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/when-one-thing-breaks/widgets/deploy-order.html) |
| Cypher script | Runnable on Aura Free, with expected results in the comments | [sre-dependency-demo.cypher](talks/when-one-thing-breaks/sre-dependency-demo.cypher) |

### Follow the Ring

Algorithmic graph data science for sub-second detection of circular fraud networks.

| Demo | What it shows | Link |
|---|---|---|
| Graph Lab | All three demos with tabs, keyboard control and the full Cypher script | [talks/follow-the-ring/](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/follow-the-ring/) |
| Ring hunter | Find loops, apply a time-ordered fraud signature, and catch a ring before the closing payment clears | [ring-hunter.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/follow-the-ring/widgets/ring-hunter.html) |
| Follow the money | Trace a scam payment through a mule tree and freeze the whole tree, not just the first account | [follow-the-money.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/follow-the-ring/widgets/follow-the-money.html) |
| Collusion ring | Shared devices and community detection expose a food-delivery collusion ring | [shared-identifiers.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/follow-the-ring/widgets/shared-identifiers.html) |
| Cypher script | Runnable on Aura Free, with expected results in the comments | [fraud-rings-demo.cypher](talks/follow-the-ring/fraud-rings-demo.cypher) |

## Embedding a widget

Each widget is a single self-contained HTML file designed at **1600 × 640 (5:2)**. It scales to fit any box, so keep that shape.

```html
<iframe
  src="https://thembelitchi.github.io/neo4j-graph-database-africa/talks/follow-the-ring/widgets/ring-hunter.html"
  style="width:100%; aspect-ratio:5/2; border:0;"
  title="Ring hunter: live Neo4j demo"
  loading="lazy"></iframe>
```

- **PowerPoint:** insert a web-viewer add-in (for example *Web Viewer*) and paste the widget URL.
- **Canva:** add an *Embed* element and paste the widget URL.
- **Google Slides:** it can't run embedded pages, so link to the URL and switch to the browser tab.
- **reveal.js / your own site:** use the iframe above.

### Controls

The widgets play on their own. To take over:

| Key | Action |
|---|---|
| Click or `→` / `Space` | Next step |
| `←` | Previous step |
| `1`–`4` | Jump to a question (clinical knowledge graph only) |
| `R` | Restart (Cypher writer only) |

Autoplay comes back after 30 seconds without input. Click inside an embedded widget once so it receives your key presses.

## Run the demo yourself

Every Graph Lab page has a *Run the demo yourself* panel with the full Cypher script for that talk, and the three newer talks also ship it as a `.cypher` file. The scripts run on Aura Free; blocks marked GDS need the Graph Data Science library (Neo4j Desktop or self-managed).

## Structure

```
index.html                              Landing page
talks/<talk>/index.html                 Graph Lab for each talk
talks/<talk>/widgets/*.html             Embeddable widgets (no build step, no dependencies)
talks/<talk>/*.cypher                   Runnable demo script

talks/power-of-the-network/             Knowledge graphs, Cypher and GraphRAG
talks/one-customer-many-records/        MDM, Customer 360 and recommendations
talks/when-one-thing-breaks/            Dependency graphs and SRE
talks/follow-the-ring/                  Circular fraud and graph data science
```

Plain HTML, CSS and JavaScript. Edit a file, push, and GitHub Pages updates in about a minute.

## Who's behind this

I'm **Thembelihle Gumede**, Neo4j Community Lead for Southern Africa, founder of Graph Database Africa, and an HPCSA-registered Biomedical Technologist turned data scientist. I build knowledge graphs for clinical labs, health and African bioeconomy projects, and I use this repo to share the demos from my talks so students can reuse them.

- GitHub: [@Thembelitchi](https://github.com/Thembelitchi)
- LinkedIn: [Thembelihle Gumede](https://www.linkedin.com/in/thembelihle-gumede-29a68095)

## Reusing the demos

The code is MIT-licensed: fork it, embed it in your own talks, adapt the Cypher for your own domain. I'd love to hear where it ends up, so open an issue or tag me.

Case-study figures in the widgets and talks are mostly vendor-published (Neo4j customer stories); they are cited where they appear and treated as self-reported.

