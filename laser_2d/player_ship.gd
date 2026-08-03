## ควบคุมยานอวกาศด้วยเมาส์และคีย์บอร์ด
extends Node2D

## ความเร็วในการเคลื่อนที่ (พิกเซล/วินาที)
@export var move_speed := 600.0
## ค่าแรงเสียดทาน (ยิ่งมาก ยิ่งหยุดเร็ว)
@export var drag_factor := 10.0

## ความเร็วปัจจุบันของยาน
var current_velocity := Vector2.ZERO

## อ้างอิงไปยังเลเซอร์ลูก (ชื่อโหนด LaserBeam2D)
@onready var laser := $LaserBeam2D

func _process(delta: float) -> void:
	# หันยานไปทางเมาส์
	look_at(get_global_mouse_position())
	# ยิงเลเซอร์เมื่อกดปุ่ม fire_weapon (คลิกซ้าย)
	laser.is_casting = Input.is_action_pressed("fire_weapon")

	# รับค่าจากคีย์บอร์ด WASD
	var input_velocity := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# คำนวณความเร็วที่ต้องการ
	var desired_velocity := input_velocity * move_speed
	# คำนวณระยะห่างระหว่างความเร็วปัจจุบันกับที่ต้องการ
	var distance := current_velocity.distance_to(desired_velocity)

	# ค่อยๆ เปลี่ยนความเร็วไปยังค่าที่ต้องการ (เอฟเฟกต์ลื่นไหล)
	current_velocity = current_velocity.move_toward(desired_velocity, distance * drag_factor * delta)
	# อัพเดทตำแหน่งยาน
	position += current_velocity * delta
