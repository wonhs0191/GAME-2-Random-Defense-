extends SceneTree

# 도감 썸네일 생성기. 시트 전체를 올리지 않도록 첫 프레임만 잘라 둔다.
# 사용: Godot --headless --path . --script res://tools/generate_thumbnails.gd
# 없어도 도감은 시트에서 직접 잘라 쓰므로 유닛을 추가할 때 필수는 아니다.

const UNIT_DIR := "res://data/units"
const OUT_DIR := "res://entities/units/thumbnails"
const SIZES := [50, 52, 56, 60] # 등급별 화면 크기

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for file_name in DirAccess.get_files_at(UNIT_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var data: Resource = load(UNIT_DIR.path_join(file_name))
		var sheet := Image.load_from_file(ProjectSettings.globalize_path(data.sheet_path))
		var frame_size: int = sheet.get_width() / data.sheet_columns
		var thumbnail := sheet.get_region(Rect2i(0, 0, frame_size, frame_size))
		var size: int = SIZES[data.grade]
		if frame_size != size:
			thumbnail.resize(size, size, Image.INTERPOLATE_NEAREST)
		thumbnail.save_png("%s/%s.png" % [OUT_DIR, data.id])
	print("generated thumbnails")
	quit()
