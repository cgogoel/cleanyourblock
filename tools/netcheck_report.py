"""Parse tools/netcheck.sh output -> unique remote endpoints per app.

Usage: python3 tools/netcheck_report.py <sockets_raw.txt> <uid_map.txt>
Columns: first seen, last seen, samples, proto, remote ip, port, uid, package(s)
"""
import sys, socket, struct, collections
raw, uidmap_path = sys.argv[1], sys.argv[2]
uids = collections.defaultdict(list)
for line in open(uidmap_path):
    parts = line.split()
    if len(parts) >= 2 and parts[1].startswith("uid:"):
        uids[int(parts[1][4:])].append(parts[0])
NAMES = {0: "root", 1000: "system", 1001: "radio", 1020: "mdnsr", 1021: "gps", 1051: "netd/dns", 1052: "network_stack", 1073: "networkstack", 2000: "shell(adb)"}
def ip4(h): return socket.inet_ntoa(struct.pack("<I", int(h, 16)))
def ip6(h):
    b = b"".join(struct.pack("<I", int(h[i:i+8], 16)) for i in range(0, 32, 8))
    if b[:12] == b"\0"*10 + b"\xff\xff": return socket.inet_ntoa(b[12:])
    return socket.inet_ntop(socket.AF_INET6, b)
seen = {}
for line in open(raw):
    f = line.split()
    if len(f) < 10 or f[2] == "sl": continue
    ts, proto, rem, st, uid = f[0], f[1], f[4], f[5], int(f[9])
    h, p = rem.split(":"); port = int(p, 16)
    ip = ip4(h) if len(h) == 8 else ip6(h)
    if port == 0 or ip in ("0.0.0.0", "::", "127.0.0.1", "::1") : continue
    k = (proto.rstrip("6"), ip, port, uid)
    if k not in seen: seen[k] = [ts, ts, 0]
    seen[k][1] = ts; seen[k][2] += 1
for (proto, ip, port, uid), (first, last, n) in sorted(seen.items(), key=lambda x: x[1][0]):
    who = ",".join(uids.get(uid, [])) or NAMES.get(uid, f"uid{uid}")
    print(f"{first}\t{last}\t{n}\t{proto}\t{ip}\t{port}\t{uid}\t{who}")
