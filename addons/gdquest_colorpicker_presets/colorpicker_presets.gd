## ปลั๊กอินสำหรับตั้งค่าสี presets ใน ColorPicker ของ Editor
@tool
extends EditorPlugin


## ชื่อไฟล์ที่เก็บค่าสี presets
const PRESETS_FILENAME := 'presets.gpl'


func _enter_tree() -> void:
	# สร้างพาธไปยังไฟล์ presets อยู่ในโฟลเดอร์เดียวกับปลั๊กอิน
	var presets_path: String = get_script().resource_path.get_base_dir().path_join(PRESETS_FILENAME)
	# เปิดไฟล์ presets
	var presets_file := FileAccess.open(presets_path, FileAccess.READ)

	# ถ้าเปิดไฟล์สำเร็จ
	if FileAccess.get_open_error() == OK:
		# อ่านเนื้อหาไฟล์ ตัดช่องว่าง แล้วแยกตามบรรทัด
		var presets_raw := presets_file.get_as_text().strip_edges().split("\n")
		presets_file.close()
		# ตัดส่วนหัวออก (ข้อมูลก่อนเครื่องหมาย #)
		presets_raw = presets_raw.slice(presets_raw.find("#") + 1)
		# แปลงข้อมูลแต่ละบรรทัดเป็นสี Color8
		var presets := Array(presets_raw).map(
			func(s: String):
				# แยกค่า R, G, B จากข้อความ
				var rgb := (Array(s.strip_edges().split(" ").slice(0, -1))
					.filter(func(s: String): return not s.is_empty())
					.map(func(s: String): return s.to_int())
				)
				return Color8(rgb[0], rgb[1], rgb[2])
		)
		# บันทึกค่าสี presets ลงในการตั้งค่า editor
		EditorInterface.get_editor_settings().set_project_metadata(
			"color_picker", "presets", presets
		)
