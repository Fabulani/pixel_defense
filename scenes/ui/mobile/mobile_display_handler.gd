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
		var screen_size = get_viewport_rect().size
		var safe_area = DisplayServer.get_display_safe_area()
		var safe_area_top = safe_area.position.y
		var safe_area_sides = safe_area.position.x
		
		if os_name == "iOS":
			# iOS scales pixels according to screen size. Account for that
			var screen_scale = DisplayServer.screen_get_scale()
			safe_area_top = (safe_area_top / screen_scale)
			safe_area_sides = (safe_area_sides / screen_scale)
			
		if screen_size.x > screen_size.y:
			# Landscape mode
			print_debug("Changed to landscape")
			var margin = 60 # TODO: test which value is best for 720p
			add_theme_constant_override("margin_top", margin)
			add_theme_constant_override("margin_right", safe_area_sides + margin)
			add_theme_constant_override("margin_bottom", margin)
			add_theme_constant_override("margin_left", safe_area_sides + margin)
		elif screen_size.x < screen_size.y:
			# Portrait mode
			print_debug("Changed to portrait")
			var margin = 60 # TODO: test which value is best for 720p
			add_theme_constant_override("margin_top", safe_area_top + margin)
			add_theme_constant_override("margin_right", margin / 2)
			add_theme_constant_override("margin_bottom", safe_area_top)
			add_theme_constant_override("margin_left", margin / 2)	
