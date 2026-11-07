extends Node

# 메뉴 화면 확인용 스크린샷. 사용법은 screenshot.gd와 같다.

func _ready() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	for scene_path in ["res://scenes/title/title_screen.tscn", "res://scenes/lobby/playsetup.tscn"]:
		var scene: Node = load(scene_path).instantiate()
		add_child(scene)
		for i in 30:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(scene_path.get_file() + ".png"))
		var setting_panel: Node = scene.find_child("SettingPanel", true, false)
		if setting_panel:
			setting_panel.open()
			for i in 5:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out_dir.path_join("setting.png"))
		scene.free()
	get_tree().quit()
