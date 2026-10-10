extends GutTest

var camera_script: Script = load("res://system/canvas/canvas_camera.gd")
var camera: Camera2D


func before_each() -> void:
	camera = autofree(camera_script.new())
	camera.movable = true


func test_two_finger_drag_pans_camera() -> void:
	press_touch(0, Vector2(0.0, 0.0))
	press_touch(1, Vector2(100.0, 0.0))
	drag_touch(0, Vector2(10.0, 0.0))

	assert_eq(camera.position, Vector2(-5.0, 0.0))


func test_pinch_zooms_camera() -> void:
	press_touch(0, Vector2(0.0, 0.0))
	press_touch(1, Vector2(100.0, 0.0))
	drag_touch(1, Vector2(120.0, 0.0))

	assert_eq(camera.zoom, Vector2(1.2, 1.2))


func test_single_finger_drag_does_not_move_camera() -> void:
	press_touch(0, Vector2(0.0, 0.0))
	drag_touch(0, Vector2(20.0, 0.0))

	assert_eq(camera.position, Vector2.ZERO)
	assert_eq(camera.zoom, Vector2.ONE)


func test_released_touch_resets_gesture() -> void:
	press_touch(0, Vector2(0.0, 0.0))
	press_touch(1, Vector2(100.0, 0.0))
	release_touch(1, Vector2(100.0, 0.0))
	drag_touch(0, Vector2(20.0, 0.0))

	assert_eq(camera.position, Vector2.ZERO)
	assert_eq(camera.zoom, Vector2.ONE)


func test_touch_gesture_stays_active_until_all_touches_are_released() -> void:
	watch_signals(camera)
	press_touch(0, Vector2(0.0, 0.0))
	press_touch(1, Vector2(100.0, 0.0))

	assert_true(camera.touch_gesture_active)
	assert_signal_emit_count(camera, "touch_gesture_started", 1)

	release_touch(1, Vector2(100.0, 0.0))
	assert_true(camera.touch_gesture_active)
	assert_signal_not_emitted(camera, "touch_gesture_ended")

	release_touch(0, Vector2(0.0, 0.0))
	assert_false(camera.touch_gesture_active)
	assert_signal_emit_count(camera, "touch_gesture_ended", 1)


func test_wheel_zoom_keeps_canvas_point_under_cursor() -> void:
	add_child(camera)
	var cursor := Vector2(100.0, 50.0)
	var point_before := canvas_point_at(cursor)

	scroll_wheel(MOUSE_BUTTON_WHEEL_UP, cursor)

	assert_gt(camera.zoom.x, 1.0)
	assert_almost_eq(canvas_point_at(cursor), point_before, Vector2(0.001, 0.001))


func test_wheel_zoom_at_screen_center_does_not_move_camera() -> void:
	add_child(camera)
	var screen_center := camera.get_viewport_rect().size / 2.0

	scroll_wheel(MOUSE_BUTTON_WHEEL_DOWN, screen_center)

	assert_lt(camera.zoom.x, 1.0)
	assert_almost_eq(camera.position, Vector2.ZERO, Vector2(0.001, 0.001))


func test_pinch_zoom_keeps_canvas_point_under_still_finger() -> void:
	add_child(camera)
	var still_finger := Vector2(100.0, 100.0)
	var point_before := canvas_point_at(still_finger)

	press_touch(0, still_finger)
	press_touch(1, Vector2(200.0, 100.0))
	drag_touch(1, Vector2(300.0, 100.0))

	assert_eq(camera.zoom, Vector2(2.0, 2.0))
	assert_almost_eq(canvas_point_at(still_finger), point_before, Vector2(0.001, 0.001))


## Returns the canvas position that is drawn at [param screen_point].
func canvas_point_at(screen_point: Vector2) -> Vector2:
	var from_center := screen_point - camera.get_viewport_rect().size / 2.0
	return camera.position + from_center / camera.zoom


func scroll_wheel(button: MouseButton, mouse_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = mouse_position
	event.pressed = true
	camera._input(event)


func press_touch(index: int, touch_position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = touch_position
	event.pressed = true
	camera._input(event)


func release_touch(index: int, touch_position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = touch_position
	event.pressed = false
	camera._input(event)


func drag_touch(index: int, touch_position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = touch_position
	camera._input(event)
