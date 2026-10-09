# Graph Database Africa · Neo4j

Talks, live demos and embeddable widgets for learning knowledge graphs, Cypher and GraphRAG, from the Neo4j community in Southern Africa.

**Live site:** https://thembelitchi.github.io/neo4j-graph-database-africa/

> Community project by Thembelihle Gumede, Neo4j Community Lead for Southern Africa. Views are my own. Neo4j® is a registered trademark of Neo4j, Inc. All demo data is fictional and for teaching only, not clinical guidance.

## Talks

### The Power of the Network (UKZN guest lecture, 2026)

An introduction to knowledge graphs and enterprise graph data science.

| Demo | What it shows | Link |
|---|---|---|
| Graph Lab | All three demos with tabs, keyboard control and the full Cypher script | [talks/ukzn-2026/](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/ukzn-2026/) |
| Cypher writer | Cypher statements type out while an antimicrobial-resistance graph builds step by step | [neo4j-cypher-writer.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/ukzn-2026/widgets/neo4j-cypher-writer.html) |
| Clinical knowledge graph | Four multi-hop questions answered across ward, lab and drug data | [neo4j-clinical-knowledge-graph.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/ukzn-2026/widgets/neo4j-clinical-knowledge-graph.html) |
| Industries explorer | Ten Neo4j case studies with headline metrics and sources | [neo4j-industries-explorer.html](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/ukzn-2026/widgets/neo4j-industries-explorer.html) |

## Embedding a widget

Each widget is a single self-contained HTML file designed at **1600 × 640 (5:2)**. It scales to fit any box, so keep that shape.

```html
<iframe
  src="https://thembelitchi.github.io/neo4j-graph-database-africa/talks/ukzn-2026/widgets/neo4j-cypher-writer.html"
  style="width:100%; aspect-ratio:5/2; border:0;"
  title="Cypher writer: live Neo4j demo"
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
| `1`–`4` | Jump to a question (clinical knowledge graph) |
| `R` | Restart (Cypher writer) |

Autoplay comes back after 30 seconds without input. Click inside an embedded widget once so it receives your key presses.

## Run the demo yourself

Open [Graph Lab](https://thembelitchi.github.io/neo4j-graph-database-africa/talks/ukzn-2026/) → *Run the demo yourself in Neo4j Aura Free* for the full Cypher script, including uniqueness constraints and a reset query.

## Structure

```
index.html                         Landing page
talks/ukzn-2026/index.html         Graph Lab for the UKZN talk
talks/ukzn-2026/widgets/*.html     Embeddable widgets (no build step, no dependencies)
```

Plain HTML, CSS and JavaScript. Edit a file, push, and GitHub Pages updates in about a minute.
