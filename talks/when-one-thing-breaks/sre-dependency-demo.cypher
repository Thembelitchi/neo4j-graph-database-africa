// =====================================================================
// When One Thing Breaks: dependency graphs for SRE
// Graph Database Africa · demo script for Neo4j 5.9+
// A fictional online shop: 15 components, 21 relationships.
// Convention: (a)-[:DEPENDS_ON]->(b) means "a needs b".
//
// HOW TO RUN
//   Works in Neo4j Sandbox (sandbox.neo4j.com, "Blank Sandbox"),
//   Neo4j Aura Free, or Neo4j Desktop.
//   Paste ONE block at a time (each statement ends with a semicolon).
//   After every change or analysis there is a "SEE IT" query that returns
//   paths, so the result opens as a graph of exactly what changed.
//   Block 10 needs Graph Data Science (Sandbox and Desktop; not Aura Free).
// =====================================================================

// ---------------------------------------------------------------------
// 0. Reset (only on a scratch database!)
// ---------------------------------------------------------------------
MATCH (n) DETACH DELETE n;

CREATE CONSTRAINT component_name IF NOT EXISTS
FOR (c:Component) REQUIRE c.name IS UNIQUE;

// ---------------------------------------------------------------------
// 1. Components
//    type: svc | data | queue | server | net
// ---------------------------------------------------------------------
UNWIND [
  {name:'web-frontend',   type:'svc',    team:'web'},
  {name:'mobile-bff',     type:'svc',    team:'mobile'},
  {name:'checkout',       type:'svc',    team:'commerce'},
  {name:'auth',           type:'svc',    team:'identity'},
  {name:'catalog',        type:'svc',    team:'catalog'},
  {name:'recs',           type:'svc',    team:'catalog'},
  {name:'payments',       type:'svc',    team:'commerce'},
  {name:'orders-db',      type:'data',   team:'platform'},
  {name:'session-cache',  type:'data',   team:'platform'},
  {name:'catalog-db',     type:'data',   team:'platform'},
  {name:'event-bus',      type:'queue',  team:'platform'},
  {name:'node-a',         type:'server', team:'infra'},
  {name:'node-b',         type:'server', team:'infra'},
  {name:'edge-router-04', type:'net',    team:'network', pool:'edge'},
  {name:'dns-internal',   type:'net',    team:'network'}
] AS row
MERGE (c:Component {name: row.name})
SET c.type = row.type, c.team = row.team, c.pool = row.pool;

// SEE IT: fifteen components, nothing connected yet
MATCH (c:Component) RETURN c;

// ---------------------------------------------------------------------
// 2. Relationships: DEPENDS_ON (needs) and HOSTED_ON (runs on)
// ---------------------------------------------------------------------
UNWIND [
  ['web-frontend','checkout'], ['web-frontend','auth'], ['web-frontend','catalog'],
  ['mobile-bff','auth'],       ['mobile-bff','recs'],
  ['checkout','auth'],         ['checkout','payments'], ['checkout','orders-db'],
  ['catalog','auth'],          ['catalog','catalog-db'],
  ['recs','catalog'],          ['auth','session-cache'], ['payments','event-bus'],
  ['node-a','edge-router-04'], ['node-a','dns-internal'],
  ['node-b','edge-router-04'], ['node-b','dns-internal']
] AS e
MATCH (a:Component {name: e[0]}), (b:Component {name: e[1]})
MERGE (a)-[:DEPENDS_ON]->(b);

UNWIND [
  ['orders-db','node-a'], ['session-cache','node-b'],
  ['catalog-db','node-b'], ['event-bus','node-a']
] AS e
MATCH (a:Component {name: e[0]}), (b:Component {name: e[1]})
MERGE (a)-[:HOSTED_ON]->(b);

// Check: expect 17 DEPENDS_ON + 4 HOSTED_ON = 21
MATCH ()-[r]->() RETURN type(r) AS type, count(*) AS n;

// SEE IT: the whole platform
MATCH p = ()-[:DEPENDS_ON|HOSTED_ON]->() RETURN p;

// ---------------------------------------------------------------------
// 3. BLAST RADIUS: walk AGAINST the arrows from the failed component
//    Expect 13 rows: node-a, node-b at 1 hop ... web-frontend at 4.
// ---------------------------------------------------------------------
MATCH (down:Component {name:'edge-router-04'})
MATCH p = (hit:Component)-[:DEPENDS_ON|HOSTED_ON]->{1,8}(down)
RETURN hit.name AS affected, hit.team AS team, min(length(p)) AS hops
ORDER BY hops, affected;

// SEE IT: everything that goes down with edge-router-04
MATCH p = (:Component)-[:DEPENDS_ON|HOSTED_ON]->{1,8}(:Component {name:'edge-router-04'})
RETURN p;

// ---------------------------------------------------------------------
// 4. ROOT CAUSE: walk WITH the arrows from the symptom
//    Expect 9 suspects: auth, orders-db, payments at 1 hop ...
// ---------------------------------------------------------------------
MATCH p = (:Component {name:'checkout'})-[:DEPENDS_ON|HOSTED_ON]->{1,8}(s:Component)
RETURN s.name AS suspect, s.type AS type, min(length(p)) AS hops
ORDER BY hops, suspect;

// SEE IT: every suspect checkout depends on
MATCH p = (:Component {name:'checkout'})-[:DEPENDS_ON|HOSTED_ON]->{1,8}(:Component)
RETURN p;

// ---------------------------------------------------------------------
// 5. CRITICALITY AUDIT: direct vs transitive dependents
//    Expect auth: 4 direct / 5 transitive;
//           edge-router-04 and dns-internal: 2 direct / 13 transitive.
// ---------------------------------------------------------------------
MATCH (c:Component)
RETURN c.name AS component,
       COUNT { (c)<-[:DEPENDS_ON|HOSTED_ON]-() } AS direct,
       size(COLLECT {
         MATCH (x)-[:DEPENDS_ON|HOSTED_ON]->{1,8}(c) RETURN DISTINCT x
       }) AS transitive
ORDER BY transitive DESC, direct DESC;

// SEE IT: dns-internal has 2 arrows pointing at it, but 13 components behind it.
// Change 'dns-internal' to 'auth' and run again to compare (5 behind it).
MATCH p = (:Component)-[:DEPENDS_ON|HOSTED_ON]->{1,8}(:Component {name:'dns-internal'})
RETURN p;

// ---------------------------------------------------------------------
// 6. STARTUP / DEPLOY WAVES (pure Cypher, no GDS needed)
//    Wave = 1 + longest path to something with no dependencies.
//    Expect 7 waves; mobile-bff starts last.
// ---------------------------------------------------------------------
MATCH (c:Component)
OPTIONAL MATCH p = (c)-[:DEPENDS_ON|HOSTED_ON]->+(leaf)
WHERE NOT (leaf)-[:DEPENDS_ON|HOSTED_ON]->()
WITH c, coalesce(max(length(p)), 0) + 1 AS wave
RETURN wave, collect(c.name) AS start_together
ORDER BY wave;

// SEE IT: the longest chain sets the number of waves (mobile-bff, 7 waves)
MATCH p = (:Component {name:'mobile-bff'})-[:DEPENDS_ON|HOSTED_ON]->+(leaf)
WHERE NOT (leaf)-[:DEPENDS_ON|HOSTED_ON]->()
RETURN p ORDER BY length(p) DESC LIMIT 1;

// ---------------------------------------------------------------------
// 7. ADD REDUNDANCY: a second router in the same pool
// ---------------------------------------------------------------------
MERGE (r:Component {name:'edge-router-05'})
SET r.type = 'net', r.team = 'network', r.pool = 'edge'
WITH r
MATCH (s:Component {type:'server'})
MERGE (s)-[:DEPENDS_ON]->(r);

// SEE IT: each server now has two routers in the 'edge' pool
MATCH p = (:Component {type:'server'})-[:DEPENDS_ON]->(:Component {pool:'edge'})
RETURN p;

// The plain walk in step 3 still says 13 affected, because it treats
// every dependency as "needs all of these". Ask the better question:
// which servers lose EVERY member of a pool when router-04 fails?
MATCH (s:Component {type:'server'})-[:DEPENDS_ON]->(r:Component)
WHERE r.pool IS NOT NULL
WITH s, r.pool AS pool, collect(r.name) AS members
WHERE all(m IN members WHERE m = 'edge-router-04')
RETURN s.name AS server_without_backup, pool;
// Expect: no rows. Delete router-05 again to see node-a and node-b return:
// MATCH (r:Component {name:'edge-router-05'}) DETACH DELETE r;

// ---------------------------------------------------------------------
// 8. BREAK IT: add a synchronous callback (creates a cycle)
// ---------------------------------------------------------------------
MATCH (p:Component {name:'payments'}), (c:Component {name:'checkout'})
MERGE (p)-[:DEPENDS_ON {mode:'sync-callback'}]->(c);

// SEE IT: the new arrow, and the one it turns into a loop
MATCH p = (:Component {name:'checkout'})-[:DEPENDS_ON]->(:Component {name:'payments'})
          -[:DEPENDS_ON]->(:Component {name:'checkout'})
RETURN p;

// Cycle check: run this in CI on every change to the dependency graph.
MATCH p = (a:Component)-[:DEPENDS_ON|HOSTED_ON]->{1,8}(a)
RETURN p, [n IN nodes(p) | n.name] AS cycle
LIMIT 5;
// Expect: checkout -> payments -> checkout (and the rotation starting at payments).

// Who can never start while the cycle exists? Anything on a cycle,
// plus anything that (transitively) needs something on a cycle.
MATCH (a:Component) WHERE EXISTS { (a)-[:DEPENDS_ON|HOSTED_ON]->{1,8}(a) }
WITH collect(a) AS onCycle
MATCH (x:Component)
OPTIONAL MATCH (x)-[:DEPENDS_ON|HOSTED_ON]->{1,8}(c)
WHERE c IN onCycle
WITH x, onCycle, count(c) AS reachesCycle
WHERE x IN onCycle OR reachesCycle > 0
RETURN collect(x.name) AS stuck, collect(x) AS nodes;
// Expect 3: web-frontend, checkout, payments.

// ---------------------------------------------------------------------
// 9. FIX IT: replace the callback with an async event
//    (payments already publishes to event-bus; checkout subscribes)
// ---------------------------------------------------------------------
MATCH (:Component {name:'payments'})-[d:DEPENDS_ON {mode:'sync-callback'}]->(:Component {name:'checkout'})
DELETE d;
MATCH (c:Component {name:'checkout'}), (b:Component {name:'event-bus'})
MERGE (c)-[:SUBSCRIBES_TO {topic:'payment.completed'}]->(b);

// SEE IT: checkout now listens to the event bus instead of being called back
MATCH p = (:Component {name:'payments'})-[:DEPENDS_ON]->(:Component {name:'event-bus'})
          <-[:SUBSCRIBES_TO]-(:Component {name:'checkout'})
RETURN p;
// SUBSCRIBES_TO is deliberately a different type: it is a soft dependency
// and is not included in the blast-radius and wave queries above.
// Re-run the cycle check: no rows.

// ---------------------------------------------------------------------
// 10. OPTIONAL: Graph Data Science (AuraDS / self-managed with GDS)
//     GDS is not included in Aura Free.
// ---------------------------------------------------------------------
// Check GDS is installed first:
RETURN gds.version();

// Project with the arrows REVERSED, so "b before a" when a needs b:
MATCH (a:Component)-[:DEPENDS_ON|HOSTED_ON]->(b:Component)
WITH gds.graph.project('startOrder', b, a) AS g
RETURN g.graphName, g.nodeCount, g.relationshipCount;

CALL gds.dag.topologicalSort.stream('startOrder', {computeMaxDistanceFromSource: true})
YIELD nodeId, maxDistanceFromSource
RETURN gds.util.asNode(nodeId).name AS component,
       toInteger(maxDistanceFromSource) + 1 AS wave
ORDER BY wave, component;

// Articulation points and bridges (undirected view of the graph).
// In this platform both return nothing: every server has two network paths.
// These procedures need GDS 2.6 or later; on older versions try the
// gds.beta. or gds.alpha. prefix.
MATCH (a:Component)-[:DEPENDS_ON|HOSTED_ON]->(b:Component)
WITH gds.graph.project('undirected', a, b, {}, {undirectedRelationshipTypes:['*']}) AS g
RETURN g.graphName;
CALL gds.articulationPoints.stream('undirected') YIELD nodeId
RETURN gds.util.asNode(nodeId).name AS articulation_point;
CALL gds.bridges.stream('undirected') YIELD from, to
RETURN gds.util.asNode(from).name, gds.util.asNode(to).name;

CALL gds.graph.drop('startOrder', false);
CALL gds.graph.drop('undirected', false);

// ---------------------------------------------------------------------
// 11. PORTFOLIO STARTER: declared vs observed dependencies
//     Load declared edges from manifests as :DECLARES and observed edges
//     from traces as :CALLS, then diff them.
// ---------------------------------------------------------------------
// Undeclared calls (seen in traces, nobody wrote them down):
// MATCH (a:Component)-[:CALLS]->(b:Component)
// WHERE NOT (a)-[:DEPENDS_ON]->(b)
// RETURN a.name, b.name;
// Declared but never observed (stale config, or a path you never test):
// MATCH (a:Component)-[:DEPENDS_ON]->(b:Component)
// WHERE NOT (a)-[:CALLS]->(b)
// RETURN a.name, b.name;
