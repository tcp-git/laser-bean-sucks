## ยิงเลเซอร์ไปตาม RayCast2D พร้อมแสดง Particles ที่จุดชนวน
## ใช้ `is_casting` เพื่อสั่งยิงและหยุดเลเซอร์
## สามารถติดกับอาวุธหรือยานอวกาศ เลเซอร์จะหมุนตามวัตถุแม่
@tool
extends RayCast2D

## ความเร็วที่เลเซอร์ยืดออกเมื่อยิงครั้งแรก (พิกเซล/วินาที)
@export var cast_speed := 7000.0
## ความยาวสูงสุดของเลเซอร์ (พิกเซล)
@export var max_length := 1400.0
## ระยะห่างจากจุดเริ่มต้นที่เริ่มวาดและยิงเลเซอร์ (พิกเซล)
@export var start_distance := 40.0
## ระยะเวลาพื้นฐานของแอนิเมชัน Tween (วินาที)
@export var growth_time := 0.1
## สีของเลเซอร์
@export var color := Color.WHITE: set = set_color

## ถ้า `true` เลเซอร์กำลังยิง
## จะเล่นแอนิเมชันปรากฏและหายไปเมื่อไม่ได้เล่น
## ดู `appear()` และ `disappear()` สำหรับข้อมูลเพิ่มเติม
@export var is_casting := false: set = set_is_casting

## ตัวแปรเก็บ Tween ปัจจุบัน
var tween: Tween = null

## อ้างอิงโหนดลูกด้วย unique name
@onready var line_2d: Line2D = %Line2D
@onready var casting_particles: GPUParticles2D = %CastingParticles2D
@onready var collision_particles: GPUParticles2D = %CollisionParticles2D
@onready var beam_particles: GPUParticles2D = %BeamParticles2D

## ความกว้างเดิมของเส้นเลเซอร์
@onready var line_width := line_2d.width


func _ready() -> void:
	# ตั้งค่าสีและสถานะการยิงเริ่มต้น
	set_color(color)
	set_is_casting(is_casting)
	# จุดเริ่มต้นและจุดสิ้นสุดของเส้นเลเซอร์
	line_2d.points[0] = Vector2.RIGHT * start_distance
	line_2d.points[1] = Vector2.ZERO
	line_2d.visible = false
	# ตั้งตำแหน่ง Particles ที่จุดเริ่มต้น
	casting_particles.position = line_2d.points[0]

	# ปิด physics process เมื่อไม่ใช่ใน editor (จะเปิดเมื่อยิง)
	if not Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	# ค่อยๆ ยืดเลเซอร์ไปยังความยาวสูงสุด
	target_position = target_position.move_toward(Vector2.RIGHT * max_length, cast_speed * delta)

	# ตำแหน่งปลายเลเซอร์ (เริ่มจากตำแหน่งปัจจุบัน)
	var laser_end_position := target_position
	# บังคับอัพเดท RayCast เพื่อเช็คการชน
	force_raycast_update()

	# ถ้าชนวัตถุ ให้ใช้จุดชนวนเป็นปลายเลเซอร์
	if is_colliding():
		laser_end_position = to_local(get_collision_point())
		# หมุน Particles ตามปกติของผิวที่ชน
		collision_particles.global_rotation = get_collision_normal().angle()
		collision_particles.position = laser_end_position

	# อัพเดทจุดสิ้นสุดของเส้นเลเซอร์
	line_2d.points[1] = laser_end_position

	# คำนวณตำแหน่งตรงกลางของลำเลเซอร์สำหรับ Beam Particles
	var laser_start_position := line_2d.points[0]
	beam_particles.position = laser_start_position + (laser_end_position - laser_start_position) * 0.5
	# ปรับความกว้างของช่องปล่อย Particles ตามความยาวลำเลเซอร์
	var extents: Vector3 = beam_particles.process_material.emission_box_extents
	extents.x = laser_end_position.distance_to(laser_start_position) * 0.5
	beam_particles.process_material.emission_box_extents = extents

	# แสดง Particles ที่จุดชนวนเฉพาะเมื่อชนวัตถุ
	collision_particles.emitting = is_colliding()


func set_is_casting(new_value: bool) -> void:
	# ถ้าค่าเท่าเดิม ไม่ต้องทำอะไร
	if is_casting == new_value:
		return
	is_casting = new_value
	# เปิด/ปิด physics process ตามสถานะการยิง
	set_physics_process(is_casting)

	# ถ้ายังไม่ได้โหลด Particles ให้ข้าม
	if beam_particles == null:
		return

	# เปิด/ปิด Particles ทั้งหมด
	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting

	if is_casting:
		# เริ่มยิง: ตั้งจุดเริ่มต้นของเลเซอร์
		var laser_start := Vector2.RIGHT * start_distance
		line_2d.points[0] = laser_start
		line_2d.points[1] = laser_start
		casting_particles.position = laser_start

		# เล่นแอนิเมชันปรากฏ
		appear()
	else:
		# หยุดยิง: รีเซ็ตตำแหน่งและซ่อน
		target_position = Vector2.ZERO
		collision_particles.emitting = false
		disappear()


func appear() -> void:
	# แสดงเส้นเลเซอร์
	line_2d.visible = true
	# ฆ่า Tween เก่าถ้ายังเล่นอยู่
	if tween and tween.is_running():
		tween.kill()
	# สร้าง Tween ใหม่: ค่อยๆ เพิ่มความกว้างจาก 0 จนถึงค่าเดิม
	tween = create_tween()
	tween.tween_property(line_2d, "width", line_width, growth_time * 2.0).from(0.0)


func disappear() -> void:
	# ฆ่า Tween เก่าถ้ายังเล่นอยู่
	if tween and tween.is_running():
		tween.kill()
	# สร้าง Tween ใหม่: ค่อยๆ ลดความกว้างจนเป็น 0 แล้วซ่อนเส้น
	tween = create_tween()
	tween.tween_property(line_2d, "width", 0.0, growth_time).from_current()
	tween.tween_callback(line_2d.hide)


func set_color(new_color: Color) -> void:
	color = new_color

	# ถ้ายังไม่ได้โหลดโหนด ให้ข้าม
	if line_2d == null:
		return

	# ตั้งสีให้ทุกส่วนของเลเซอร์
	line_2d.modulate = new_color
	casting_particles.modulate = new_color
	collision_particles.modulate = new_color
	beam_particles.modulate = new_color
