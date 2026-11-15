extends RefCounted
## Builds SpriteFrames from a sprite sheet. One row per animation: [name, frame_count, fps, loop].


static func make_frames(sheet_path: String, fw: int, fh: int, anims: Array) -> SpriteFrames:
    var tex: Texture2D = load(sheet_path)
    var sf := SpriteFrames.new()
    if sf.has_animation("default"):
        sf.remove_animation("default")
    for row in range(anims.size()):
        var a: Array = anims[row]
        var nm: String = a[0]
        sf.add_animation(nm)
        sf.set_animation_speed(nm, float(a[2]))
        sf.set_animation_loop(nm, bool(a[3]))
        for i in range(int(a[1])):
            var at := AtlasTexture.new()
            at.atlas = tex
            at.region = Rect2(i * fw, row * fh, fw, fh)
            at.filter_clip = true
            sf.add_frame(nm, at)
    return sf
