// =====================================================================
// Follow the Ring: graph data science for circular fraud networks
// Graph Database Africa · demo script for Neo4j 5.9+
// Three fictional datasets, matching the three Graph Lab widgets:
//   A. a transfer ring          (ring hunter)
//   B. a scam-money tree        (follow the money)
//   C. a food-delivery collusion ring (shared identifiers)
//
// HOW TO RUN
//   Works in Neo4j Sandbox (sandbox.neo4j.com, "Blank Sandbox"),
//   Neo4j Aura Free, or Neo4j Desktop.
//   Paste ONE block at a time (each statement ends with a semicolon).
//   After every change or analysis there is a "SEE IT" query (or the query
//   itself returns paths), so the result opens as a graph.
//   Block C4 needs Graph Data Science (Sandbox and Desktop; not Aura Free).
// =====================================================================

// ---------------------------------------------------------------------
// 0. Reset (only on a scratch database!)
// ---------------------------------------------------------------------
MATCH (n) DETACH DELETE n;

CREATE CONSTRAINT account_id IF NOT EXISTS FOR (a:Account) REQUIRE a.id IS UNIQUE;
CREATE INDEX transfer_at IF NOT EXISTS FOR ()-[t:TRANSFERRED]-() ON (t.at);

// =====================================================================
// A. THE RING
// =====================================================================

// A1. Eleven accounts, thirteen transfers
UNWIND [
  ['A-101','A-205',50000,'2026-03-14T09:02'], ['A-205','A-318',48500,'2026-03-14T09:14'],
  ['A-318','A-442',47100,'2026-03-14T09:27'], ['A-442','A-101',45600,'2026-03-14T09:41'],
  ['B-510','B-623',12000,'2026-03-01T10:00'], ['B-623','B-777', 3100,'2026-03-09T10:00'],
  ['B-777','B-510',  800,'2026-03-28T10:00'],
  ['C-904','A-101', 1500,'2026-03-02T10:00'], ['A-205','B-510',  600,'2026-03-03T10:00'],
  ['A-318','C-901',  700,'2026-03-05T10:00'], ['C-901','C-902', 2300,'2026-03-06T10:00'],
  ['C-902','B-777',  950,'2026-03-07T10:00'], ['B-623','C-903', 4000,'2026-03-12T10:00']
] AS row
MERGE (a:Account {id: row[0]})
MERGE (b:Account {id: row[1]})
CREATE (a)-[:TRANSFERRED {amount: row[2], at: datetime(row[3])}]->(b);

// SEE IT: eleven accounts, thirteen transfers
MATCH p = (:Account)-[:TRANSFERRED]->(:Account) RETURN p;

// A2. Every loop of 3 to 6 transfers (expect 2 loops, each returned
//     once per starting account: 4 rows for the A ring, 3 for the B loop)
MATCH p = (a:Account)-[:TRANSFERRED]->{3,6}(a)
RETURN p, [n IN nodes(p) | n.id] AS loop;

// A3. The ring signature: time-ordered, amounts decaying by at most 10%
//     per hop, whole trip inside one hour.
//     Expect exactly 1 row: start A-101, amounts [50000, 48500, 47100, 45600].
//     The time-order rule also removes the duplicate rotations.
MATCH p = (a:Account)
          (()-[t:TRANSFERRED]->()){3,6}
          (a)
WHERE all(i IN range(1, size(t)-1)
          WHERE t[i].at > t[i-1].at
            AND t[i].amount >= 0.9 * t[i-1].amount)
  AND t[-1].at < t[0].at + duration('PT1H')
RETURN p,
       a.id AS start,
       [x IN t | x.amount] AS amounts,
       duration.between(t[0].at, t[-1].at).minutes AS minutes;

// A4. REAL TIME: test a payment BEFORE it is written.
//     Pretend A-442 -> A-101 (R45,600 at 09:41) has not happened yet:
MATCH (:Account {id:'A-442'})-[t:TRANSFERRED]->(:Account {id:'A-101'}) DELETE t;

//     Anchored check: walk from the receiver back to the sender.
//     Expect 1 row: [A-101, A-205, A-318, A-442] -> hold the payment.
WITH 'A-442' AS fromId, 'A-101' AS toId, 45600 AS amount,
     datetime('2026-03-14T09:41') AS at
MATCH p = (:Account {id: toId})
          (()-[t:TRANSFERRED]->()){2,5}
          (:Account {id: fromId})
WHERE all(i IN range(1, size(t)-1)
          WHERE t[i].at > t[i-1].at
            AND t[i].amount >= 0.9 * t[i-1].amount)
  AND at > t[-1].at
  AND amount >= 0.9 * t[-1].amount
  AND at < t[0].at + duration('PT1H')
RETURN p, [n IN nodes(p) | n.id] AS ring_this_payment_would_close;

//     Prefix the query above with PROFILE to see how few rows it touches.
//     Then put the transfer back:
MATCH (a:Account {id:'A-442'}), (b:Account {id:'A-101'})
CREATE (a)-[:TRANSFERRED {amount: 45600, at: datetime('2026-03-14T09:41')}]->(b);

// SEE IT: the ring is complete again
MATCH p = (:Account {id:'A-101'})-[:TRANSFERRED]->{4}(:Account {id:'A-101'})
RETURN p;

// =====================================================================
// B. FOLLOW THE MONEY
// =====================================================================

// B1. Two victims, six mule accounts, one ATM.
//     balance = what is still sitting in the account from this money.
CREATE (v1:Victim {id:'V-1'}), (v2:Victim {id:'V-2'}), (atm:CashPoint {id:'ATM-77'})
WITH v1, v2, atm
UNWIND [['M1',3000],['M2',100],['M3',100],['M4',4500],['M5',0],['M6',7900]] AS row
MERGE (m:Account {id: row[0]}) SET m.balance = row[1];

MATCH (v1:Victim {id:'V-1'}), (v2:Victim {id:'V-2'}), (atm:CashPoint {id:'ATM-77'}),
      (m1:Account {id:'M1'}), (m2:Account {id:'M2'}), (m3:Account {id:'M3'}),
      (m4:Account {id:'M4'}), (m5:Account {id:'M5'}), (m6:Account {id:'M6'})
CREATE (v1)-[:PAID {amount:20000, at:datetime('2026-03-20T14:05')}]->(m1),
       (v2)-[:PAID {amount: 6000, at:datetime('2026-03-19T15:00')}]->(m3),
       (m1)-[:TRANSFERRED {amount:9000, at:datetime('2026-03-20T14:07')}]->(m2),
       (m1)-[:TRANSFERRED {amount:8000, at:datetime('2026-03-20T14:08')}]->(m3),
       (m2)-[:TRANSFERRED {amount:4500, at:datetime('2026-03-20T14:20')}]->(m4),
       (m2)-[:TRANSFERRED {amount:4400, at:datetime('2026-03-20T14:22')}]->(m5),
       (m3)-[:TRANSFERRED {amount:7900, at:datetime('2026-03-20T14:31')}]->(m6),
       (m5)-[:CASHED_OUT  {amount:4400, at:datetime('2026-03-20T15:02')}]->(atm);

// SEE IT: two victims, six mule accounts, one ATM
MATCH p = (x)-[:PAID|TRANSFERRED|CASHED_OUT]->()
WHERE x:Victim OR x.balance IS NOT NULL
RETURN p;

// B2. Old rule: first receiving account only. Expect R3,000.
MATCH p = (:Victim {id:'V-1'})-[:PAID]->(first:Account)
RETURN p, first.id, first.balance AS recoverable;

// B3. Walk the tree forwards, time-ordered, after the scam payment.
//     Expect M2, M3 at hop 1 and M4, M5, M6 at hop 2 (M1 is hop 0).
MATCH (:Victim {id:'V-1'})-[pay:PAID]->(m1:Account)
MATCH p = (m1)(()-[t:TRANSFERRED]->()){1,4}(m:Account)
WHERE t[0].at > pay.at
  AND all(i IN range(1, size(t)-1) WHERE t[i].at > t[i-1].at)
RETURN m.id AS account, min(length(p)) AS hops_after_M1, m.balance AS balance,
       collect(p) AS paths
ORDER BY hops_after_M1, account;

// B4. Freeze the whole tree. Expect R15,600 recoverable (78%),
//     and R4,400 already cashed out.
MATCH (:Victim {id:'V-1'})-[pay:PAID]->(m1:Account)
OPTIONAL MATCH (m1)(()-[t:TRANSFERRED]->()){1,4}(m:Account)
WHERE t[0].at > pay.at
  AND all(i IN range(1, size(t)-1) WHERE t[i].at > t[i-1].at)
WITH pay, m1, collect(DISTINCT m) AS downstream
WITH pay, downstream + m1 AS tree
UNWIND tree AS acc
OPTIONAL MATCH (acc)-[c:CASHED_OUT]->(:CashPoint)
WITH pay.amount AS paid,
     sum(acc.balance) AS recoverable,
     sum(coalesce(c.amount, 0)) AS cashed_out
RETURN paid, recoverable, round(100.0 * recoverable / paid) AS pct, cashed_out;

// SEE IT: the whole tree that gets frozen, plus the ATM where R4,400 escaped
MATCH p = (:Victim {id:'V-1'})-[:PAID]->(:Account)
          -[:TRANSFERRED*0..4]->(:Account)-[:CASHED_OUT*0..1]->()
RETURN p;

// B5. One mule, two victims: who else paid into this tree?
//     Expect V-1 -> M1 and V-2 -> M3.
MATCH (:Victim {id:'V-1'})-[pay:PAID]->(m1:Account)
OPTIONAL MATCH (m1)(()-[t:TRANSFERRED]->()){1,4}(m:Account)
WHERE t[0].at > pay.at
WITH m1, collect(DISTINCT m) AS downstream
WITH downstream + m1 AS tree
UNWIND tree AS acc
MATCH p = (v:Victim)-[:PAID]->(acc)
RETURN p, v.id AS victim, acc.id AS paid_into
ORDER BY victim;

// =====================================================================
// C. COLLUSION RING (food-delivery pattern, like iFood's)
// =====================================================================

// C1. Customers, restaurants, couriers and the devices they log in from
UNWIND ['user-1','user-2','user-3','user-4','user-5','user-6','user-7'] AS id
CREATE (:Customer {id: id});
UNWIND ['Rest. A','Rest. B','Rest. C'] AS name
CREATE (:Restaurant {name: name});
UNWIND ['courier-1','courier-2'] AS id
CREATE (:Courier {id: id});
UNWIND ['phone-1','tablet-2'] AS id
CREATE (:Device {id: id});

UNWIND [['user-1','Rest. A',9],['user-2','Rest. A',11],['user-3','Rest. A',8],['user-4','Rest. A',9],
        ['user-7','Rest. A',1],['user-7','Rest. B',2],['user-5','Rest. B',3],['user-5','Rest. C',2],
        ['user-6','Rest. C',4]] AS row
MATCH (c:Customer {id: row[0]}), (r:Restaurant {name: row[1]})
CREATE (c)-[:ORDERED {orders: row[2]}]->(r);

UNWIND [['courier-1','Rest. A'],['courier-2','Rest. B'],['courier-2','Rest. C']] AS row
MATCH (c:Courier {id: row[0]}), (r:Restaurant {name: row[1]})
CREATE (c)-[:DELIVERS_FOR]->(r);

UNWIND [['user-1','phone-1'],['user-2','phone-1'],['user-3','phone-1'],['user-4','phone-1'],
        ['courier-1','phone-1'],['user-5','tablet-2'],['user-6','tablet-2']] AS row
MATCH (a {id: row[0]}), (d:Device {id: row[1]})
WHERE a:Customer OR a:Courier
CREATE (a)-[:USES_DEVICE]->(d);

// SEE IT: customers, restaurants, couriers and devices
MATCH p = ()-[:ORDERED|DELIVERS_FOR|USES_DEVICE]->()
RETURN p;

// C2. Shared devices. Expect phone-1 with 5 users, tablet-2 with 2.
MATCH p = (a)-[:USES_DEVICE]->(d:Device)
WITH d, collect(a.id) AS users, collect(p) AS paths
WHERE size(users) > 1
RETURN d.id AS device, users, paths;

// C3. Score each shared device (plain Cypher, works on Aura Free).
//     Expect phone-1: 5 accounts, 37 orders, 100% to Rest. A,
//                     courier on the same phone -> flag for review
//            tablet-2: 2 accounts, 9 orders, 67% to Rest. C -> household
MATCH (d:Device)<-[:USES_DEVICE]-(a)
WITH d, collect(a) AS users
WHERE size(users) > 1
UNWIND users AS u
MATCH (u)-[o:ORDERED]->(r:Restaurant)
WITH d, users, r, sum(o.orders) AS n
WITH d, users, collect([r.name, n]) AS spread, sum(n) AS total
WITH d, users, total,
     reduce(best = ['', 0], x IN spread | CASE WHEN x[1] > best[1] THEN x ELSE best END) AS top
RETURN d.id AS device,
       size(users) AS accounts,
       total AS orders,
       top[0] AS top_restaurant,
       round(100.0 * top[1] / total) AS pct_to_top,
       EXISTS {
         MATCH (c:Courier)-[:USES_DEVICE]->(d)
         MATCH (c)-[:DELIVERS_FOR]->(:Restaurant {name: top[0]})
       } AS courier_on_same_device
ORDER BY pct_to_top DESC;

// SEE IT: everything around the flagged phone
MATCH p = (:Device {id:'phone-1'})<-[:USES_DEVICE]-()-[:ORDERED|DELIVERS_FOR]->(:Restaurant)
RETURN p;

// C4. GDS: community detection (Louvain).
//     Check GDS is installed first:  RETURN gds.version();
//     Expect two communities:
//       {user-1..4, courier-1, phone-1, Rest. A}
//       {user-5, user-6, user-7, courier-2, tablet-2, Rest. B, Rest. C}
MATCH (a)-[r:ORDERED|DELIVERS_FOR|USES_DEVICE]->(b)
WITH gds.graph.project('orders', a, b, {}, {undirectedRelationshipTypes: ['*']}) AS g
RETURN g.graphName, g.nodeCount, g.relationshipCount;

CALL gds.louvain.stream('orders')
YIELD nodeId, communityId
WITH communityId, collect(gds.util.asNode(nodeId)) AS members
RETURN communityId,
       size(members) AS size,
       [x IN members | coalesce(x.id, x.name)] AS names
ORDER BY size DESC;

// SEE IT: each community drawn with only its internal relationships
CALL gds.louvain.stream('orders')
YIELD nodeId, communityId
WITH communityId, collect(gds.util.asNode(nodeId)) AS members
UNWIND members AS a
MATCH p = (a)-[:ORDERED|DELIVERS_FOR|USES_DEVICE]->(b)
WHERE b IN members
RETURN communityId, collect(p) AS paths;

CALL gds.graph.drop('orders', false);

// =====================================================================
// PORTFOLIO STARTER: PaySim
// PaySim (Lopez-Rojas et al., 2016) is a synthetic mobile-money dataset
// generated from one month of logs of a mobile-money service in an
// African country. It's on Kaggle. Load a sample as
// (:Account)-[:TRANSFERRED {amount, step}]->(:Account), plant a few rings
// and mule trees with the patterns above, and show your queries find
// them while ordinary transfers pass.
// =====================================================================
