## เลเซอร์แบบง่ายที่ยิงไปตาม RayCast2D
## ใช้ `is_casting` เพื่อสั่งยิงและหยุดเลเซอร์
@tool
extends RayCast2D

## ความเร็วที่เลเซอร์ยืดออกเมื่อยิงครั้งแรก (พิกเซล/วินาที)
@export var cast_speed := 7000.0
## ความยาวสูงสุดของเลเซอร์ (พิกเซล)
@export var max_length := 1400.0
## ระยะห่างจากจุดเริ่มต้นที่เริ่มยิงเลเซอร์ (พิกเซล)
@export var start_distance := 40.0
## ถ้า `true` เลเซอร์กำลังยิง
@export var is_casting := false: set = set_is_casting


func _ready() -> void:
	set_is_casting(is_casting)

	# ปิด physics process เมื่อไม่ใช่ใน editor
	if not Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	# ค่อยๆ ยืดเลเซอร์ไปยังความยาวสูงสุด
	target_position = target_position.move_toward(Vector2.RIGHT * max_length, cast_speed * delta)

	# บังคับอัพเดท RayCast
	force_raycast_update()


func set_is_casting(new_value: bool) -> void:
	# ถ้าค่าเท่าเดิม ไม่ต้องทำอะไร
	if is_casting == new_value:
		return
	is_casting = new_value

	# เปิด/ปิด physics process ตามสถานะการยิง
	set_physics_process(is_casting)

	if is_casting:
		# เริ่มยิง: ตั้งจุดเริ่มต้นของเลเซอร์
		target_position = Vector2.RIGHT * start_distance
	else:
		# หยุดยิง: รีเซ็ตตำแหน่ง
		target_position = Vector2.ZERO
