extends GdUnitTestSuite


func test_viewport_is_320x180() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_width")).is_equal(320)
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_height")).is_equal(180)


func test_stretch_keeps_integer_scale() -> void:
	assert_str(ProjectSettings.get_setting("display/window/stretch/mode")).is_equal("canvas_items")
	assert_str(ProjectSettings.get_setting("display/window/stretch/aspect")).is_equal("keep")
	assert_str(ProjectSettings.get_setting("display/window/stretch/scale_mode")).is_equal("integer")


func test_pixels_stay_crisp() -> void:
	assert_int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")) \
		.is_equal(Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
	assert_bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel")).is_true()


func test_story_state_autoload_is_running() -> void:
	assert_object(get_tree().root.get_node_or_null("StoryState")).is_not_null()


func test_renderer_is_compatibility() -> void:
	assert_str(ProjectSettings.get_setting("rendering/renderer/rendering_method")).is_equal("gl_compatibility")
