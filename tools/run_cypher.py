"""Run a .cypher demo script statement by statement and report results."""
import json, re, sys
from neo4j import GraphDatabase
from neo4j.graph import Node, Relationship, Path

def statements(text):
    out, buf, in_str, q = [], [], False, ''
    i = 0
    while i < len(text):
        c = text[i]
        if not in_str and text.startswith('//', i):
            j = text.find('\n', i); i = len(text) if j < 0 else j; continue
        if in_str:
            buf.append(c)
            if c == '\\': buf.append(text[i+1]); i += 2; continue
            if c == q: in_str = False
        elif c in "'\"":
            in_str, q = True, c; buf.append(c)
        elif c == ';':
            s = ''.join(buf).strip()
            if s: out.append(s)
            buf = []
        else:
            buf.append(c)
        i += 1
    s = ''.join(buf).strip()
    if s: out.append(s)
    return out

def show(v):
    if isinstance(v, Node):
        p = dict(v); return '(' + ':'.join(v.labels) + ' ' + str(p.get('id', p.get('name', p.get('number', p.get('address', p.get('sku', '')))))) + ')'
    if isinstance(v, Relationship):
        return '[' + v.type + ']'
    if isinstance(v, Path):
        return 'PATH(' + '->'.join(show(n) for n in v.nodes) + ')'
    if isinstance(v, list):
        return '[' + ', '.join(show(x) for x in v[:8]) + (', ...' if len(v) > 8 else '') + ']'
    return repr(v)

def main(uri, path):
    drv = GraphDatabase.driver(uri, auth=('neo4j', 'testpassword'))
    stmts = statements(open(path).read())
    fails = 0
    print(f'=== {path}: {len(stmts)} statements')
    for n, s in enumerate(stmts, 1):
        first = s.splitlines()[0][:90]
        try:
            with drv.session() as sess:
                res = sess.run(s)
                rows = list(res)
                summ = res.consume()
                c = summ.counters
            graphy = any(isinstance(v, (Node, Relationship, Path)) or (isinstance(v, list) and any(isinstance(x, (Node, Relationship, Path)) for x in v)) for r in rows for v in r.values())
            print(f'--- [{n}] OK rows={len(rows)} graph={"yes" if graphy else "no"} '
                  f'+nodes={c.nodes_created} +rels={c.relationships_created} -nodes={c.nodes_deleted} -rels={c.relationships_deleted} :: {first}')
            for r in rows[:12]:
                print('      ', {k: show(v) for k, v in r.items()})
            if len(rows) > 12: print(f'       ... {len(rows)-12} more rows')
        except Exception as e:
            fails += 1
            print(f'!!! [{n}] ERROR :: {first}\n      {type(e).__name__}: {str(e)[:600]}')
    drv.close()
    print(f'=== {path}: {fails} errors')
    return fails

if __name__ == '__main__':
    sys.exit(1 if main(sys.argv[1], sys.argv[2]) else 0)
