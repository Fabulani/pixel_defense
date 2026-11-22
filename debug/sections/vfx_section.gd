extends "res://debug/sections/debug_section.gd"
## VFX: one-shot effects at the view centre, camera shake.

var _ctx: Context


func build(ctx: Context) -> void:
	_ctx = ctx
	var flow: HFlowContainer = Ui.add_flow(content)
	Ui.add_button(flow, "Muzzle", _on_vfx_pressed.bind(&"muzzle"))
	Ui.add_button(flow, "Impact", _on_vfx_pressed.bind(&"impact"))
	Ui.add_button(flow, "Death", _on_vfx_pressed.bind(&"death"))
	Ui.add_button(flow, "Deflect", _on_vfx_pressed.bind(&"deflect"))
	Ui.add_button(flow, "Coins +5", _on_vfx_pressed.bind(&"coins"))
	Ui.add_button(flow, "Built", _on_vfx_pressed.bind(&"built"))
	Ui.add_button(flow, "Upgraded", _on_vfx_pressed.bind(&"upgraded"))
	Ui.add_button(flow, "Shake", _on_vfx_pressed.bind(&"shake"))


func _on_vfx_pressed(kind: StringName) -> void:
	var at: Vector2 = _ctx.camera.get_screen_center_position()
	var vfx: VfxManager = _ctx.vfx
	match kind:
		&"muzzle":
			vfx.play_muzzle(at, -PI / 2.0, Color.WHITE)
		&"impact":
			vfx.play_impact(at, Vector2.UP, Color.WHITE)
		&"death":
			vfx.play_death(at, Color.WHITE)
		&"deflect":
			vfx.play_deflect(at)
		&"coins":
			vfx.play_coin_popup(at, 5)
		&"built":
			vfx.play_tower_built(at)
		&"upgraded":
			vfx.play_tower_upgraded(at)
		&"shake":
			_ctx.camera.shake(0.7)
