extends MarginContainer

func _ready() -> void:
	_handle_screen_resize()
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_handle_screen_resize()
		
func _handle_screen_resize() -> void:
	""" Handle resizing screen for Portrait/Landscape mode on mobile. """
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		var screen_size: Vector2 = get_viewport_rect().size
		var safe_area: Rect2i = DisplayServer.get_display_safe_area()
		var safe_area_top := safe_area.position.y as float
		var safe_area_sides := safe_area.position.x as float
		
		if os_name == "iOS":
			# iOS scales pixels according to screen size. Account for that
			var screen_scale: float = DisplayServer.screen_get_scale()
			safe_area_top /=  screen_scale
			safe_area_sides /= screen_scale
			
		var margin := 60.0
		if screen_size.x > screen_size.y:
			# Landscape mode
			add_theme_constant_override("margin_top", roundi(margin))
			add_theme_constant_override("margin_right", roundi(safe_area_sides + margin))
			add_theme_constant_override("margin_bottom", roundi(margin))
			add_theme_constant_override("margin_left", roundi(safe_area_sides + margin))
		elif screen_size.x < screen_size.y:
			# Portrait mode
			add_theme_constant_override("margin_top", roundi(safe_area_top + margin))
			add_theme_constant_override("margin_right", roundi(margin / 2.0))
			add_theme_constant_override("margin_bottom", roundi(safe_area_top))
			add_theme_constant_override("margin_left", roundi(margin / 2.0))
