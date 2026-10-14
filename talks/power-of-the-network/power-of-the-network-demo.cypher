// =====================================================================
// The Power of the Network: a clinical knowledge graph, written live
// Graph Database Africa · demo script for Neo4j 5
// All patient data is fictional and for teaching only, not clinical guidance.
//
// HOW TO RUN
//   Works in Neo4j Sandbox (sandbox.neo4j.com, "Blank Sandbox"),
//   Neo4j Aura Free, or Neo4j Desktop.
//   Paste ONE block at a time (each block ends with a semicolon) and run it.
//   Every step ends by RETURNing what it just added, so the result opens
//   as a graph. Switch between Graph and Table view to see both.
// =====================================================================


// ---------- 0. Reset (demo database only!) ----------
MATCH (n) DETACH DELETE n;


// ---------- 0b. Constraints make MERGE safe and fast ----------
CREATE CONSTRAINT patient_id IF NOT EXISTS FOR (p:Patient) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT isolate_id IF NOT EXISTS FOR (i:Isolate) REQUIRE i.id IS UNIQUE;
CREATE CONSTRAINT drug_name IF NOT EXISTS FOR (d:Drug) REQUIRE d.name IS UNIQUE;


// ---------- STEP 1. A patient and a specimen ----------
// MERGE = match or create; CREATE = always new.
// Run this block twice: the patient stays single, the specimen duplicates.
MERGE (p:Patient {id:'PT-001'})
CREATE (s:Specimen {id:'SP-1001', type:'Blood culture'})
MERGE (p)-[r:HAS_SPECIMEN {collected: date('2026-10-01')}]->(s)
RETURN p, r, s;

// SEE IT: how many specimens does PT-001 have now?
MATCH path = (:Patient {id:'PT-001'})-[:HAS_SPECIMEN]->(:Specimen)
RETURN path;
// Clean up the duplicate before moving on:
MATCH (s:Specimen {id:'SP-1001'})
WITH s ORDER BY elementId(s) SKIP 1
DETACH DELETE s;


// ---------- STEP 2. The lab identifies an isolate ----------
MATCH (s:Specimen {id:'SP-1001'})
MERGE (t:LabTest {method:'MALDI-TOF'})
MERGE (s)-[:TESTED_BY]->(t)
MERGE (i:Isolate {id:'ISO-77'})
MERGE (t)-[:IDENTIFIED]->(i)
MERGE (o:Pathogen {name:'Klebsiella pneumoniae'})
MERGE (i)-[:INSTANCE_OF]->(o)
WITH s
MATCH path = (s)-[:TESTED_BY]->()-[:IDENTIFIED]->()-[:INSTANCE_OF]->()
RETURN path;


// ---------- STEP 3. A resistance mechanism is detected ----------
MATCH (i:Isolate {id:'ISO-77'})
MERGE (m:Mechanism {name:'KPC', gene:'blaKPC'})
MERGE (i)-[r:CARRIES]->(m)
RETURN i, r, m;


// ---------- STEP 4. Drug knowledge joins the graph ----------
MATCH (m:Mechanism {name:'KPC'})
MERGE (d:Drug {name:'Meropenem'}) SET d.class = 'Carbapenem'
MERGE (m)-[r:CONFERS_RESISTANCE_TO]->(d)
RETURN m, r, d;


// ---------- STEP 5. Susceptibility results live on relationships ----------
MATCH (i:Isolate {id:'ISO-77'}), (d:Drug {name:'Meropenem'})
MERGE (c:Drug {name:'Ceftazidime-avibactam'})
MERGE (i)-[r1:AST_RESULT {sir:'R'}]->(d)
MERGE (i)-[r2:AST_RESULT {sir:'S'}]->(c)
RETURN i, r1, d, r2, c;


// ---------- STEP 6. The multi-hop question ----------
// Which drugs should we avoid for this patient, and why?
MATCH path = (:Patient {id:'PT-001'})-[:HAS_SPECIMEN]->()-[:TESTED_BY]->()
             -[:IDENTIFIED]->(:Isolate)-[:CARRIES]->(m)-[:CONFERS_RESISTANCE_TO]->(d:Drug)
RETURN path, m.name AS mechanism, d.name AS avoid;
// Expect: KPC, Meropenem.


// ---------- SEE IT: the whole knowledge graph ----------
MATCH path = (:Patient {id:'PT-001'})-[*1..6]->()
RETURN path;
