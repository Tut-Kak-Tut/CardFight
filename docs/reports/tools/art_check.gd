extends SceneTree
func _initialize() -> void:
	var names: Array = []
	for f in DirAccess.get_files_at("res://assets/art/placeholder/"):
		if f.ends_with(".svg"): names.append(f.get_basename())
	var bad := 0; var nfinal := 0; var nph := 0
	for n in names:
		var p := Art.path(n)
		var t := Art.tex(n)
		var fin := p.begins_with("res://assets/art/final/")
		var ph = load("res://assets/art/placeholder/" + n + ".svg")
		var sz = t.get_size() if t else Vector2.ZERO
		var psz = ph.get_size()
		var ok = t != null and sz == psz
		if fin: nfinal += 1
		else: nph += 1
		if not ok: bad += 1
		print("ART %-28s %-6s %s size=%s ph=%s %s" % [n, "FINAL" if fin else "ph", Art.is_final(n), sz, psz, "OK" if ok else "SIZE_MISMATCH"])
	for f in DirAccess.get_files_at("res://assets/art/final/"):
		if f.ends_with(".svg") and not names.has(f.get_basename()): print("EXTRA_FINAL_NO_PLACEHOLDER ", f)
	print("locked: ", Art.path("player_mage_locked"), " sil=", Art.needs_silhouette("player_mage_locked"))
	print("ART_SUMMARY total=%d final=%d placeholder=%d bad=%d" % [names.size(), nfinal, nph, bad])
	quit(0)
