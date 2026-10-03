class_name MapGenerator extends RefCounted

const PEACEFUL := ["rest", "merchant"]


static func generate(cfg: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var map := {}
	for _rebuild in range(50):
		map = _build_structure(cfg, rng)
		for _try in range(500):
			_assign_types(map, cfg, rng)
			if _check_types(map, cfg, true).is_empty():
				map.erase("_preds")
				return map
	push_error("MapGenerator: failed to build a valid map")
	map.erase("_preds")
	return map


static func _pos(i: int, n: int) -> float:
	return 0.5 if n <= 1 else float(i) / float(n - 1)


static func _crosses(edges: Array, a: int, b: int) -> bool:
	for e in edges:
		if (a < e[0] and b > e[1]) or (a > e[0] and b < e[1]):
			return true
	return false


static func _has_edge(edges: Array, i: int, j: int) -> bool:
	for e in edges:
		if e[0] == i and e[1] == j:
			return true
	return false


static func _nearest(p: float, m: int) -> int:
	var best := 0
	var bd := INF
	for j in range(m):
		var d := absf(_pos(j, m) - p)
		if d < bd - 0.000001:
			bd = d
			best = j
	return best


static func _build_structure(cfg: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var layers_n := int(cfg["layers"])
	var min_n := int(cfg["min_nodes"])
	var max_n := int(cfg["max_nodes"])
	var nodes: Array = []
	var layers: Array = []
	for l in range(layers_n):
		var cnt := 1
		if l == 0:
			cnt = int(cfg["first_layer_nodes"])
		elif l < layers_n - 1:
			cnt = rng.randi_range(min_n, max_n)
		var ids: Array = []
		for i in range(cnt):
			var id := nodes.size()
			nodes.append({"id": id, "layer": l, "index": i, "type": "boss" if l == layers_n - 1 else "battle", "next": []})
			ids.append(id)
		layers.append(ids)
	for l in range(layers_n - 1):
		var a: Array = layers[l]
		var b: Array = layers[l + 1]
		var edges: Array = []
		var has_in: Array = []
		has_in.resize(b.size())
		has_in.fill(false)
		for i in range(a.size()):
			var j := _nearest(_pos(i, a.size()), b.size())
			edges.append([i, j])
			has_in[j] = true
		if l < layers_n - 2:
			for i in range(a.size()):
				if rng.randf() < 0.4:
					var base := _nearest(_pos(i, a.size()), b.size())
					var j := base + (1 if rng.randf() < 0.5 else -1)
					if j < 0 or j >= b.size() or _has_edge(edges, i, j):
						continue
					if not _crosses(edges, i, j):
						edges.append([i, j])
						has_in[j] = true
		for j in range(b.size()):
			if has_in[j]:
				continue
			var cands: Array = range(a.size())
			cands.sort_custom(func(x, y): return absf(_pos(x, a.size()) - _pos(j, b.size())) < absf(_pos(y, a.size()) - _pos(j, b.size())))
			for i in cands:
				if not _crosses(edges, i, j):
					edges.append([i, j])
					has_in[j] = true
					break
		for e in edges:
			nodes[a[e[0]]]["next"].append(b[e[1]])
		for id in a:
			nodes[id]["next"].sort()
	return {"nodes": nodes, "layers": layers}


static func _assign_types(map: Dictionary, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var layers: Array = map["layers"]
	var nodes: Array = map["nodes"]
	var w: Dictionary = cfg["weights"]
	var el: Array = cfg["elite_layers"]
	var rl: Array = cfg["rest_layers"]
	if not map.has("_preds"):
		var pr := {}
		for n in nodes:
			for nx in n["next"]:
				if not pr.has(nx):
					pr[nx] = []
				pr[nx].append(n["id"])
		map["_preds"] = pr
	var preds: Dictionary = map["_preds"]
	var used := {"elite": 0, "rest": 0, "merchant": 0}
	var forced := {}
	var rl_i := int(cfg["rest_required_layer"]) - 1
	var ml_i := int(cfg["merchant_required_layer"]) - 1
	if rl_i >= 1 and rl_i < layers.size() - 1:
		var rid: int = layers[rl_i][rng.randi_range(0, layers[rl_i].size() - 1)]
		forced[rid] = "rest"
		used["rest"] += 1
		if ml_i >= 1 and ml_i < layers.size() - 1:
			var ok: Array = []
			for mid in layers[ml_i]:
				if not (rid in nodes[mid]["next"]) and not (mid in nodes[rid]["next"]):
					ok.append(mid)
			if not ok.is_empty():
				forced[ok[rng.randi_range(0, ok.size() - 1)]] = "merchant"
				used["merchant"] += 1
	for fid in forced:
		nodes[fid]["type"] = forced[fid]
	for l in range(1, layers.size() - 1):
		var ln := l + 1
		var kinds: Array = ["battle", "merchant"]
		if ln >= int(el[0]) and ln <= int(el[1]) and ln > 3:
			kinds.append("elite")
		if ln >= int(rl[0]) and ln <= int(rl[1]):
			kinds.append("rest")
		var total := 0.0
		for k in kinds:
			total += float(w[k])
		for id in layers[l]:
			if forced.has(id):
				continue
			var near_peace := false
			for pid in preds[id]:
				if nodes[pid]["type"] in PEACEFUL:
					near_peace = true
			for nid in nodes[id]["next"]:
				if forced.has(nid):
					near_peace = true
			var kk: Array = []
			var tt := 0.0
			for k in kinds:
				if near_peace and k in PEACEFUL:
					continue
				if k == "elite" and used["elite"] >= int(cfg["elite_count"][1]):
					continue
				if k == "rest" and used["rest"] >= int(cfg["rest_count"][1]):
					continue
				if k == "merchant" and used["merchant"] >= int(cfg.get("merchant_max", 99)):
					continue
				kk.append(k)
				tt += float(w[k])
			var r := rng.randf() * tt
			var chosen: String = kk[0]
			for k in kk:
				r -= float(w[k])
				if r < 0.0:
					chosen = k
					break
			nodes[id]["type"] = chosen
			if used.has(chosen):
				used[chosen] += 1


static func _layer_has(map: Dictionary, l: int, type: String) -> bool:
	if l < 0 or l >= map["layers"].size():
		return false
	for id in map["layers"][l]:
		if map["nodes"][id]["type"] == type:
			return true
	return false


static func _check_types(map: Dictionary, cfg: Dictionary, fast := false) -> Array[String]:
	var errs: Array[String] = []
	var nodes: Array = map["nodes"]
	var counts := {"elite": 0, "merchant": 0, "rest": 0}
	var mid := 0
	var mid_battle := 0
	for n in nodes:
		if counts.has(n["type"]):
			counts[n["type"]] += 1
		if n["layer"] > 0 and n["type"] != "boss":
			mid += 1
			if n["type"] == "battle":
				mid_battle += 1
	if mid > 0 and float(mid_battle) / float(mid) > float(cfg.get("max_battle_share", 1.0)):
		errs.append("too many battles")
		if fast:
			return errs
	var ec: Array = cfg["elite_count"]
	var rc: Array = cfg["rest_count"]
	if counts["elite"] < int(ec[0]) or counts["elite"] > int(ec[1]):
		errs.append("elite count %d" % counts["elite"])
		if fast:
			return errs
	if counts["merchant"] > int(cfg.get("merchant_max", 99)):
		errs.append("merchant count %d > max" % counts["merchant"])
		if fast:
			return errs
	if counts["merchant"] < int(cfg["merchant_min"]):
		errs.append("merchant count %d" % counts["merchant"])
		if fast:
			return errs
	if counts["rest"] < int(rc[0]) or counts["rest"] > int(rc[1]):
		errs.append("rest count %d" % counts["rest"])
		if fast:
			return errs
	if not _layer_has(map, int(cfg["merchant_required_layer"]) - 1, "merchant"):
		errs.append("no merchant in required layer")
		if fast:
			return errs
	if not _layer_has(map, int(cfg["rest_required_layer"]) - 1, "rest"):
		errs.append("no rest in required layer")
		if fast:
			return errs
	var el: Array = cfg["elite_layers"]
	var rl: Array = cfg["rest_layers"]
	for n in nodes:
		var ln: int = n["layer"] + 1
		if n["type"] == "elite" and (ln < int(el[0]) or ln > int(el[1]) or ln <= 3):
			errs.append("elite in wrong layer %d" % ln)
			if fast:
				return errs
		if n["type"] == "rest" and (ln < int(rl[0]) or ln > int(rl[1])):
			errs.append("rest in wrong layer %d" % ln)
			if fast:
				return errs
		if n["type"] in PEACEFUL:
			for nx in n["next"]:
				if nodes[nx]["type"] in PEACEFUL:
					errs.append("peaceful edge %d->%d" % [n["id"], nx])
					if fast:
						return errs
	return errs


static func validate(map: Dictionary, cfg: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	var nodes: Array = map["nodes"]
	var layers: Array = map["layers"]
	if layers.size() != int(cfg["layers"]):
		errs.append("layer count %d" % layers.size())
		return errs
	var has_in := {}
	for i in range(nodes.size()):
		var n: Dictionary = nodes[i]
		if n["id"] != i:
			errs.append("id mismatch %d" % i)
		if n["type"] != "boss" and n["next"].is_empty():
			errs.append("node %d has no next" % i)
		for nx in n["next"]:
			has_in[nx] = true
			if nodes[nx]["layer"] != n["layer"] + 1:
				errs.append("edge %d->%d skips layers" % [i, nx])
	for n in nodes:
		if n["layer"] > 0 and not has_in.has(n["id"]):
			errs.append("node %d has no incoming" % n["id"])
	for l in range(layers.size() - 1):
		var edges: Array = []
		for id in layers[l]:
			for nx in nodes[id]["next"]:
				edges.append([nodes[id]["index"], nodes[nx]["index"]])
		for e in edges:
			for f in edges:
				if e[0] < f[0] and e[1] > f[1]:
					errs.append("crossing in layer %d" % l)
	var last: Array = layers[layers.size() - 1]
	if last.size() != 1 or nodes[last[0]]["type"] != "boss":
		errs.append("last layer must be single boss")
	else:
		for id in layers[layers.size() - 2]:
			if nodes[id]["next"] != last:
				errs.append("penultimate node %d not linked to boss" % id)
	for id in layers[0]:
		if nodes[id]["type"] != "battle":
			errs.append("first layer not battle")
	errs.append_array(_check_types(map, cfg))
	return errs
