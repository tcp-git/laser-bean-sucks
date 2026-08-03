## ควบคุมดาวเคราะห์น้อยให้หมุนวน
extends StaticBody2D

## ความเร็วในการหมุนแบบสุ่ม (เรดิยัน/วินาที)
var rotation_speed := randf_range(PI / 20.0, PI / 4.0)

## อ้างอิง Sprite2D ลูก
@onready var sprite_2d: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	# หมุน sprite ตามความเร็วที่กำหนด
	sprite_2d.rotate(rotation_speed * delta)
