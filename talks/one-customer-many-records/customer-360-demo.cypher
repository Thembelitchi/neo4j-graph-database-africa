// =====================================================================
// One Customer, Many Records — Customer 360 + recommendations demo
// Graph Database Africa · Neo4j 5.26+ / 2026.x (Aura Free works)
// All people, emails and phone numbers are fictional.
// Run one block at a time (separate statements with the ; shown).
// =====================================================================

// ---------- 0. Reset (demo database only!) and constraints ----------
MATCH (n) DETACH DELETE n;
CREATE CONSTRAINT customer_id IF NOT EXISTS FOR (c:Customer) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT person_id   IF NOT EXISTS FOR (p:Person)   REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT product_sku IF NOT EXISTS FOR (p:Product)  REQUIRE p.sku IS UNIQUE;

// ---------- 1. Source records from three silos ----------
// Identifiers become their own nodes (one node per value).
UNWIND [
 {id:'CRM-001',  src:'CRM',     name:'Thandi Mokoena', email:'thandi.m@example.com', phone:'+27825550101', device:null},
 {id:'WEB-7781', src:'SHOP',    name:'T. Mokoena',     email:'thandi.m@example.com', phone:null,           device:'DEV-A1'},
 {id:'SUP-3302', src:'SUPPORT', name:'Thandi M',       email:null,                   phone:'+27825550101', device:'DEV-A1'},
 {id:'CRM-002',  src:'CRM',     name:'Sipho Dlamini',  email:'sipho.d@example.com',  phone:null,           device:null},
 {id:'WEB-7790', src:'SHOP',    name:'Sipho Dlamini',  email:'sipho.d@example.com',  phone:null,           device:'DEV-B2'},
 {id:'SUP-3310', src:'SUPPORT', name:'S. Dlamini',     email:null,                   phone:null,           device:'DEV-B2'},
 {id:'WEB-8041', src:'SHOP',    name:'Lerato Naidoo',  email:null,                   phone:null,           device:'DEV-C3'},
 {id:'SUP-3321', src:'SUPPORT', name:'Lerato N',       email:null,                   phone:null,           device:'DEV-C3'},
 {id:'WEB-8100', src:'SHOP',    name:'Ayesha Khan',    email:'ayesha.k@example.com', phone:null,           device:null},
 {id:'WEB-8200', src:'SHOP',    name:'Bongani Zulu',   email:null,                   phone:null,           device:null}
] AS r
MERGE (c:Customer {id:r.id}) SET c.source = r.src, c.name = r.name
FOREACH (_ IN CASE WHEN r.email  IS NULL THEN [] ELSE [1] END |
  MERGE (e:Email  {address:r.email}) MERGE (c)-[:HAS_EMAIL]->(e))
FOREACH (_ IN CASE WHEN r.phone  IS NULL THEN [] ELSE [1] END |
  MERGE (p:Phone  {number:r.phone})  MERGE (c)-[:HAS_PHONE]->(p))
FOREACH (_ IN CASE WHEN r.device IS NULL THEN [] ELSE [1] END |
  MERGE (d:Device {id:r.device})     MERGE (c)-[:USES_DEVICE]->(d));

// ---------- 2. The trap: support logged three people with the call-centre line ----------
MATCH (c:Customer) WHERE c.id IN ['SUP-3302','SUP-3310','SUP-3321']
MERGE (p:Phone {number:'+27860100200'}) SET p.note = 'call centre'
MERGE (c)-[:HAS_PHONE]->(p);

// ---------- 3. Products and purchases (recorded against source records) ----------
UNWIND [['P-100','Trail Running Shoes'],['P-101','Hydration Vest'],['P-102','Energy Gels'],
        ['P-103','GPS Watch'],['P-104','Headlamp'],['P-105','Yoga Mat'],['P-106','Water Bottle']] AS p
MERGE (:Product {sku:p[0], name:p[1]});

UNWIND [['WEB-7781','P-100'],['WEB-7781','P-102'],
        ['WEB-7790','P-100'],['WEB-7790','P-101'],['WEB-7790','P-104'],
        ['WEB-8041','P-100'],['WEB-8041','P-101'],['WEB-8041','P-103'],
        ['WEB-8100','P-102'],['WEB-8100','P-101'],['WEB-8100','P-105'],
        ['WEB-8200','P-105'],['WEB-8200','P-106']] AS x
MATCH (c:Customer {id:x[0]}), (p:Product {sku:x[1]})
MERGE (c)-[:PURCHASED]->(p);

// ---------- 4. Order, duplicate payment, refund and support ticket (for the assistant demo) ----------
MATCH (c:Customer {id:'WEB-7781'}), (s:Product {sku:'P-100'})
MERGE (o:Order {id:'ORD-551'}) MERGE (c)-[:PLACED]->(o) MERGE (o)-[:CONTAINS]->(s)
MERGE (p1:Payment {id:'PAY-901'}) SET p1.amount = 1899
MERGE (p2:Payment {id:'PAY-902'}) SET p2.amount = 1899, p2.note = 'duplicate'
MERGE (p1)-[:FOR]->(o) MERGE (p2)-[:FOR]->(o)
MERGE (r:Refund {id:'REF-77'}) SET r.status = 'pending'
MERGE (r)-[:REFUNDS]->(p2);

MATCH (c:Customer {id:'SUP-3302'}), (o:Order {id:'ORD-551'})
MERGE (t:Ticket {id:'TCK-1'}) SET t.topic = 'Size exchange', t.status = 'shipped'
MERGE (c)-[:LOGGED]->(t) MERGE (t)-[:ABOUT]->(o);

// ---------- 5a. Show the trap (read-only): without a guard, strangers link up ----------
MATCH (a:Customer)-[:HAS_EMAIL|HAS_PHONE|USES_DEVICE]->(i)<-[:HAS_EMAIL|HAS_PHONE|USES_DEVICE]-(b:Customer)
WHERE a.id < b.id
RETURN a.id, b.id, labels(i)[0] AS via, coalesce(i.address, i.number, i.id) AS value
ORDER BY via, a.id;
// Expect pairs like SUP-3302 / SUP-3310 via the call-centre phone. Those are different people.

// ---------- 5b. Deterministic matching with a supernode guard ----------
// Skip identifiers shared by more than 2 records (the call-centre line has 3).
MATCH (a:Customer)-[:HAS_EMAIL|HAS_PHONE|USES_DEVICE]->(i)<-[:HAS_EMAIL|HAS_PHONE|USES_DEVICE]-(b:Customer)
WHERE a.id < b.id AND COUNT { (i)<--() } <= 2
WITH a, b, count(DISTINCT i) AS strength
MERGE (a)-[m:SAME_AS]->(b) SET m.strength = strength;

// ---------- 6. Golden records (Cypher version; use GDS WCC at scale, block 12) ----------
MATCH (c:Customer)
OPTIONAL MATCH (c)-[:SAME_AS]-+(o:Customer)
WITH c, [c] + collect(DISTINCT o) AS cluster
WITH c, reduce(k = c.id, x IN cluster | CASE WHEN x.id < k THEN x.id ELSE k END) AS key
MERGE (p:Person {id:'PER-' + key})
MERGE (c)-[:RESOLVES_TO]->(p);

// Survivorship: CRM wins the name, then the shop; keep provenance
MATCH (p:Person)<-[:RESOLVES_TO]-(c:Customer)
WITH p, collect(c) AS recs
SET p.name    = coalesce(head([r IN recs WHERE r.source = 'CRM'  | r.name]),
                         head([r IN recs WHERE r.source = 'SHOP' | r.name]), recs[0].name),
    p.sources = [r IN recs | r.source + ':' + r.id];

MATCH (p:Person) RETURN p.id, p.name, p.sources ORDER BY p.id;
// Expect 5 people from 10 records:
//   PER-CRM-001 Thandi Mokoena (CRM, SHOP, SUPPORT)   PER-CRM-002 Sipho Dlamini (CRM, SHOP, SUPPORT)
//   PER-SUP-3321 Lerato Naidoo (SHOP, SUPPORT)        PER-WEB-8100 Ayesha Khan   PER-WEB-8200 Bongani Zulu

// ---------- 7. Consent lives in the graph ----------
MATCH (p:Person {id:'PER-CRM-001'})
MERGE (k:Consent {id:'CONSENT-PER-CRM-001'}) SET k.directMarketing = false, k.recorded = date('2026-03-01')
MERGE (p)-[:HAS_CONSENT]->(k);

// ---------- 8. Customer 360: everything about Thandi, across all three systems ----------
MATCH (p:Person {id:'PER-CRM-001'})<-[:RESOLVES_TO]-(c:Customer)-[rel:PURCHASED|PLACED|LOGGED]->(x)
RETURN p.name, c.source, c.id, type(rel) AS interaction,
       coalesce(x.name, x.topic, x.id) AS item
ORDER BY c.source;

// ---------- 9. The assistant's bounded query ("charged twice?") ----------
MATCH (:Person {id:'PER-CRM-001'})<-[:RESOLVES_TO]-(c)-[:PLACED]->(o:Order)
      -[:CONTAINS]->(:Product {name:'Trail Running Shoes'})
OPTIONAL MATCH (o)<-[:FOR]-(pay:Payment)
OPTIONAL MATCH (ref:Refund)-[:REFUNDS]->(pay)
OPTIONAL MATCH (t:Ticket)-[:ABOUT]->(o)
RETURN o.id, collect(DISTINCT pay.id) AS payments, collect(DISTINCT ref.id + ' ' + ref.status) AS refunds,
       collect(DISTINCT t.id + ' ' + t.status) AS tickets;

// Consent check before any marketing
MATCH (:Person {id:'PER-CRM-001'})-[:HAS_CONSENT]->(k:Consent)
RETURN k.directMarketing AS mayMarket;   // false

// ---------- 10. User-based collaborative filtering, popularity-damped ----------
MATCH (t:Person {id:'PER-CRM-001'})<-[:RESOLVES_TO]-()-[:PURCHASED]->(p:Product)
WITH t, collect(DISTINCT p) AS owned
UNWIND owned AS p
MATCH (p)<-[:PURCHASED]-()-[:RESOLVES_TO]->(peer:Person)
WHERE peer <> t
WITH owned, peer, count(DISTINCT p) AS overlap
MATCH (peer)<-[:RESOLVES_TO]-()-[:PURCHASED]->(rec:Product)
WHERE NOT rec IN owned
WITH rec, sum(overlap) AS score, COUNT { (rec)<-[:PURCHASED]-() } AS pop
RETURN rec.name, score, pop, round(score / log(2 + pop), 3) AS damped
ORDER BY damped DESC LIMIT 5;
// Expect: Hydration Vest 1.864, Headlamp 0.91, GPS Watch 0.91, Yoga Mat 0.721

// ---------- 10b. Experiment: make the water bottle a best-seller, then rerun block 10 ----------
UNWIND ['WEB-7790','WEB-8041','WEB-8100'] AS id
MATCH (c:Customer {id:id}), (b:Product {sku:'P-106'})
MERGE (c)-[:PURCHASED]->(b);
// Rerun block 10: raw score ties Vest and Water Bottle at 3; damped keeps Vest first (1.864 vs 1.674).

// ---------- 11. Item-to-item: "bought X, also bought Y" (Jaccard over people) ----------
MATCH (x:Product {sku:'P-100'})<-[:PURCHASED]-()-[:RESOLVES_TO]->(b:Person)
WITH x, collect(DISTINCT b) AS buyersX
MATCH (y:Product)<-[:PURCHASED]-()-[:RESOLVES_TO]->(b2:Person) WHERE y <> x
WITH buyersX, y, collect(DISTINCT b2) AS buyersY
WITH y, size([b IN buyersY WHERE b IN buyersX]) AS shared, size(buyersX) + size(buyersY) AS total
WHERE shared > 0
RETURN y.name, round(toFloat(shared) / (total - shared), 3) AS jaccard
ORDER BY jaccard DESC;

// ---------- 12. (Needs Graph Data Science) WCC identity clusters with the same guard ----------
MATCH (c:Customer)-[:HAS_EMAIL|HAS_PHONE|USES_DEVICE]->(i)
WHERE COUNT { (i)<--() } <= 2
WITH gds.graph.project('ids', c, i, {}, {undirectedRelationshipTypes:['*']}) AS g
RETURN g.nodeCount, g.relationshipCount;

CALL gds.wcc.stream('ids') YIELD nodeId, componentId
WITH gds.util.asNode(nodeId) AS n, componentId WHERE n:Customer
RETURN componentId, collect(n.id) AS records ORDER BY size(records) DESC;

CALL gds.graph.drop('ids');
// Note: records with no identifiers (WEB-8200) are not in this projection; Cypher block 6 handles them.
