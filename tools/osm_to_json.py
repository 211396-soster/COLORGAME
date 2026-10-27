#!/usr/bin/env python3
"""Converte map_osm.xml (OpenStreetMap) em data/city.json compacto para o Godot.
Uso: python3 tools/osm_to_json.py map_osm.xml data/city.json
Dados (c) OpenStreetMap contributors, licenca ODbL."""
import sys, json, math
from lxml import etree
src = sys.argv[1] if len(sys.argv) > 1 else "map_osm.xml"
dst = sys.argv[2] if len(sys.argv) > 2 else "data/city.json"
CLAT, CLON = -28.25739, -52.40791   # centro de Passo Fundo (origem do mundo)
R = 6371000.0
def proj(lat, lon):
    x = math.radians(lon - CLON) * R * math.cos(math.radians(CLAT))
    z = -math.radians(lat - CLAT) * R   # norte = -Z no Godot
    return (round(x, 1), round(z, 1))
nodes = {}; ways = []; places = []
for ev, el in etree.iterparse(src, events=("end",), tag=("node", "way")):
    if el.tag == "node":
        nodes[el.get("id")] = proj(float(el.get("lat")), float(el.get("lon")))
        tags = {t.get("k"): t.get("v") for t in el.findall("tag")}
        if tags.get("place") in ("suburb", "neighbourhood", "quarter", "city") and tags.get("name"):
            places.append({"n": tags["name"], "p": list(nodes[el.get("id")])})
        elif tags.get("name") and (tags.get("amenity") or tags.get("shop") or tags.get("tourism")):
            places.append({"n": tags["name"], "p": list(nodes[el.get("id")]), "poi": 1})
    else:
        tags = {t.get("k"): t.get("v") for t in el.findall("tag")}
        pts = [nodes[n.get("ref")] for n in el.findall("nd") if n.get("ref") in nodes]
        if len(pts) >= 2: ways.append((tags, pts))
    el.clear()
ROAD_W = {"motorway":12,"trunk":12,"primary":11,"secondary":10,"tertiary":9,"unclassified":8,
          "residential":7,"living_street":6,"service":4,"trunk_link":7,"primary_link":7,
          "secondary_link":7,"tertiary_link":6}
# ---- afastar prédios das ruas (grade espacial de segmentos) ----
GRID = {}
def _cell(x, z): return (int(x // 60), int(z // 60))
for t, p in ways:
    h = t.get("highway")
    if h in ROAD_W and ROAD_W[h] >= 6:
        need = ROAD_W[h] / 2 + 3.0
        for i in range(len(p) - 1):
            seg = (p[i][0], p[i][1], p[i+1][0], p[i+1][1], need)
            cx0, cz0 = _cell(min(seg[0], seg[2]) - 12, min(seg[1], seg[3]) - 12)
            cx1, cz1 = _cell(max(seg[0], seg[2]) + 12, max(seg[1], seg[3]) + 12)
            for a in range(cx0, cx1 + 1):
                for b in range(cz0, cz1 + 1):
                    GRID.setdefault((a, b), []).append(seg)
def clear_roads(pts):
    total = [0.0, 0.0]
    for _ in range(5):
        worst = 0.0; wdir = (0.0, 0.0)
        samples = list(pts) + [((pts[i][0]+pts[(i+1)%len(pts)][0])/2, (pts[i][1]+pts[(i+1)%len(pts)][1])/2) for i in range(len(pts))]
        for (x, z) in samples:
            x += total[0]; z += total[1]
            for s in GRID.get(_cell(x, z), []):
                abx = s[2]-s[0]; abz = s[3]-s[1]
                tt = ((x-s[0])*abx + (z-s[1])*abz) / (abx*abx + abz*abz + 1e-6)
                tt = max(0.0, min(1.0, tt))
                qx = s[0]+abx*tt; qz = s[1]+abz*tt
                d = math.hypot(x-qx, z-qz)
                if d < s[4] and s[4]-d > worst:
                    worst = s[4]-d
                    if d < 0.01: wdir = (-abz, abx)
                    else: wdir = ((x-qx)/d, (z-qz)/d)
                    n = math.hypot(*wdir) or 1.0
                    wdir = (wdir[0]/n, wdir[1]/n)
        if worst < 0.05: break
        total[0] += wdir[0]*(worst+0.1); total[1] += wdir[1]*(worst+0.1)
    if math.hypot(*total) > 9.0: return None
    return total
roads=[]; builds=[]; parks=[]; water=[]
LIM=3300
def inside(p):
    return any(abs(p[i])<LIM and abs(p[i+1])<LIM for i in range(0,len(p),2))
def simp(p, tol):
    if len(p) < 3: return p
    out=[p[0]]
    for q in p[1:-1]:
        if math.hypot(q[0]-out[-1][0], q[1]-out[-1][1]) >= tol: out.append(q)
    out.append(p[-1]); return out
for t, p in ways:
    h = t.get("highway")
    if h in ROAD_W:
        roads.append({"w": ROAD_W[h], "n": t.get("name",""), "p": [c for q in simp(p,4) for c in q],
                      "o": 1 if t.get("oneway")=="yes" else 0})
    elif "building" in t and len(p) >= 4:
        lv = t.get("building:levels")
        try: hh = float(t.get("height")) if t.get("height") else (float(lv)*3.0 if lv else 0)
        except: hh = 0
        sh = clear_roads(p[:-1])
        if sh is None: continue
        builds.append({"h": hh, "p": [round(c, 1) for q in p[:-1] for c in (q[0]+sh[0], q[1]+sh[1])]})
    elif (t.get("leisure") in ("park","pitch","garden","playground") or t.get("landuse") in ("grass","forest","recreation_ground","cemetery") or t.get("natural") in ("wood","scrub")) and len(p) >= 4:
        parks.append([c for q in simp(p,5)[:-1] for c in q])
    elif (t.get("natural")=="water" or t.get("waterway") in ("river","stream")) and len(p) >= 2:
        water.append({"c": 1 if t.get("natural")=="water" else 0, "p":[c for q in simp(p,5) for c in q]})
roads=[r for r in roads if inside(r["p"])]
builds=[b for b in builds if inside(b["p"])]
parks=[q for q in parks if inside(q)]
water=[w for w in water if inside(w["p"])]
places=[q for q in places if abs(q["p"][0])<LIM and abs(q["p"][1])<LIM]
json.dump({"roads":roads,"buildings":builds,"parks":parks,"water":water,"places":places},
          open(dst,"w"), separators=(",",":"), ensure_ascii=False)
print("ruas",len(roads),"predios",len(builds),"parques",len(parks),"agua",len(water),"lugares",len(places))
