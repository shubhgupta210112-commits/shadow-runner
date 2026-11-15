extends SceneTree
## Builds a SpriteFrames .tres for every sprite sheet described by
## assets/sprites/sprites.json.  Run (after importing assets):
##   godot --headless --path . --script res://tools/build_frames.gd

func _init() -> void:
	var f := FileAccess.open("res://assets/sprites/sprites.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	var count := 0
	for sprite_name in data:
		var meta: Dictionary = data[sprite_name]
		var tex := load("res://assets/sprites/%s.png" % sprite_name) as Texture2D
		if tex == null:
			push_error("missing texture for " + sprite_name)
			continue
		var fs := SpriteFrames.new()
		var fw: int = int(meta["frame"][0])
		var fh: int = int(meta["frame"][1])
		var first := true
		for anim_name in meta["anims"]:
			var a: Dictionary = meta["anims"][anim_name]
			if anim_name == "default":
				pass
			elif first and fs.has_animation("default"):
				fs.rename_animation("default", anim_name)
			else:
				fs.add_animation(anim_name)
			first = false
			fs.set_animation_speed(anim_name, float(a["fps"]))
			fs.set_animation_loop(anim_name, bool(a["loop"]))
			for i in int(a["frames"]):
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(i * fw, int(a["row"]) * fh, fw, fh)
				fs.add_frame(anim_name, at)
		var err := ResourceSaver.save(fs, "res://assets/sprites/%s_frames.tres" % sprite_name)
		if err != OK:
			push_error("save failed for %s: %d" % [sprite_name, err])
		count += 1
	print("frames built: ", count)
	quit()
