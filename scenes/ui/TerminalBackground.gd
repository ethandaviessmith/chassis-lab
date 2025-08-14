@tool
class_name TerminalBackground
extends Control

# Import RetroUtils
const SCANLINE_SPACING = 3
const SCANLINE_WIDTH = 1

@export var border_thickness: int = 4
@export var rounded_corners: bool = true
@export var corner_radius: int = 8
@export var border_color: Color = Color("#5555aa")
@export var background_color: Color = Color("#2a2a3a")
@export var terminal_header: String = "CHASSIS-LAB v0.8.5"
@export var header_color: Color = Color("#33ff33") 
@export var show_header: bool = true
@export var show_scanlines: bool = true
@export var scanline_opacity: float = 0.05

# Private vars
var _header_font: Font
var _scanline_material: ShaderMaterial

func _ready() -> void:
	# Load font
	_header_font = load("res://assets/BoldPixels1.4.ttf")
	
	if show_scanlines:
		# Create scanline shader
		var shader = load("res://assets/shaders/crt_effect.gdshader")
		if shader:
			_scanline_material = ShaderMaterial.new()
			_scanline_material.shader = shader
			_scanline_material.set_shader_parameter("scan_opacity", scanline_opacity)
			_scanline_material.set_shader_parameter("line_spacing", SCANLINE_SPACING)
			_scanline_material.set_shader_parameter("line_thickness", SCANLINE_WIDTH)
	
	# Make sure we redraw when resized
	resized.connect(_on_resized)
	
	# Force redraw
	queue_redraw()

func _on_resized() -> void:
	queue_redraw()

func _draw() -> void:
	# Draw background
	var rect = Rect2(Vector2.ZERO, size)
	
	# Draw the main terminal background
	if rounded_corners:
		draw_rounded_rectangle(rect, background_color, corner_radius)
	else:
		draw_rect(rect, background_color, true)
	
	# Draw the border
	if border_thickness > 0:
		if rounded_corners:
			draw_rounded_rectangle_border(rect, border_color, corner_radius, border_thickness)
		else:
			# Top border
			draw_rect(Rect2(0, 0, size.x, border_thickness), border_color, true)
			# Bottom border
			draw_rect(Rect2(0, size.y - border_thickness, size.x, border_thickness), border_color, true)
			# Left border
			draw_rect(Rect2(0, border_thickness, border_thickness, size.y - 2 * border_thickness), border_color, true)
			# Right border
			draw_rect(Rect2(size.x - border_thickness, border_thickness, border_thickness, size.y - 2 * border_thickness), border_color, true)
	
	# Draw the header if enabled
	if show_header and terminal_header != "":
		var header_rect = Rect2(border_thickness, border_thickness, 
							   size.x - 2 * border_thickness, 20)
		
		# Header background
		draw_rect(header_rect, border_color, true)
		
		# Header text
		if _header_font != null:
			var font_size = 12
			draw_string(_header_font, Vector2(header_rect.position.x + 10, header_rect.position.y + 15),
						terminal_header, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, header_color)

# Helper to draw rounded rectangles
func draw_rounded_rectangle(rect: Rect2, color: Color, radius: float) -> void:
	# Ensure radius isn't too large for the rectangle
	radius = min(min(rect.size.x, rect.size.y) * 0.5, radius)
	
	# Corner positions
	var top_left = rect.position
	var top_right = Vector2(rect.position.x + rect.size.x, rect.position.y)
	var bottom_right = Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y)
	var bottom_left = Vector2(rect.position.x, rect.position.y + rect.size.y)
	
	# Draw main rectangle minus corners
	draw_rect(Rect2(top_left.x, top_left.y + radius, rect.size.x, rect.size.y - 2 * radius), color, true)
	draw_rect(Rect2(top_left.x + radius, top_left.y, rect.size.x - 2 * radius, radius), color, true)
	draw_rect(Rect2(top_left.x + radius, top_left.y + rect.size.y - radius, rect.size.x - 2 * radius, radius), color, true)
	
	# Draw rounded corners
	draw_circle(Vector2(top_left.x + radius, top_left.y + radius), radius, color)
	draw_circle(Vector2(top_right.x - radius, top_right.y + radius), radius, color)
	draw_circle(Vector2(bottom_right.x - radius, bottom_right.y - radius), radius, color)
	draw_circle(Vector2(bottom_left.x + radius, bottom_left.y - radius), radius, color)

# Helper to draw rounded rectangle borders
func draw_rounded_rectangle_border(rect: Rect2, color: Color, radius: float, thickness: float) -> void:
	# Inner rectangle for border calculation
	var inner_rect = Rect2(
		rect.position + Vector2(thickness, thickness),
		rect.size - Vector2(2, 2) * thickness
	)
	
	# Draw the outer rounded rectangle
	draw_rounded_rectangle(rect, color, radius)
	
	# Draw the inner rounded rectangle with background color to create a border
	draw_rounded_rectangle(inner_rect, background_color, max(radius - thickness, 0))

# Apply scanline material to this control
func apply_scanlines() -> void:
	if show_scanlines and _scanline_material:
		material = _scanline_material
