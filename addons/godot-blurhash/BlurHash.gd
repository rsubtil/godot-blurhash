extends Node

## Encodes the supplied texture to a BlurHash. [code]components_x[/code] and
## [code]components_y[/code] control how many colors to extract and add on each
## axis for the blurred image.
func encode(tex: Texture2D, components_x: int = 4, components_y: int = 3) -> String:
	if components_x < 1 or components_x > 9 or components_y < 1 or components_y > 9:
		return ""
	
	var tex_data := tex.get_image().get_data()
	var format := tex.get_image().get_format()
	if format != Image.FORMAT_RGB8 and format != Image.FORMAT_RGBA8:
		# Format not supported
		return ""
	var blurhash := ""

	var dc : Vector3
	var ac := []
	for y in range(components_y):
		for x in range(components_x):
			var color := _multiply_basis_func(x, y, tex.get_width(), tex.get_height(), tex_data, format)
			if x | y == 0:
				dc = color
			else:
				ac.push_back(color)

	var size_flag := (components_x - 1) + (components_y - 1) * 9
	blurhash += _to_base83(size_flag, 1)
	
	var max_value : float
	if ac.size() > 0:
		var actual_max_value := 0.0
		for ac_color in ac:
			var color_max_value := max(abs(ac_color.x), max(abs(ac_color.y), abs(ac_color.z)))
			actual_max_value = max(color_max_value, actual_max_value)
		var quantised_max_value := int(max(0, min(82, floor(actual_max_value * 166 - 0.5))))
		max_value = (quantised_max_value + 1) / 166.0
		blurhash += _to_base83(quantised_max_value, 1)
	else:
		max_value = 1.0
		blurhash += _to_base83(0, 1)
	
	blurhash += _to_base83(_encode_dc(dc), 4)
	
	for ac_color in ac:
		blurhash += _to_base83(_encode_ac(ac_color, max_value), 2)
	
	return blurhash

## Decodes the supplied BlurHash. [code]width[/code] and [code]height[/code] are
## used when creating the texture. It's recommended to use low width/height values
## since the image doesn't have much detail anyways, and then scale the final
## image to the necessary size. That way, such operation is done on the GPU
## which is much, much faster than on CPU. The [code]punch[/code] parameter
## controls the output's contrast. Increase it to make the colors stand out more.
func decode(blurhash: String, width: int, height: int, punch: int = 1) -> Texture:
	if not is_valid_blurhash(blurhash):
		return null
	punch = max(1, punch)

	var components := _from_base83(blurhash.substr(0, 1))
	var ny := (components / 9) + 1
	var nx := (components % 9) + 1
	var max_value := (_from_base83(blurhash.substr(1, 1)) + 1) / 166.0
	if is_equal_approx(max_value, 0):
		return null

	var colors := []
	for i in range(nx * ny):
		if i == 0:
			var value := _from_base83(blurhash.substr(2, 4))
			if value == -1:
				return null
			colors.push_back(_decode_dc(value))
		else:
			var value := _from_base83(blurhash.substr(4 + i * 2, 2))
			if value == -1:
				return null
			colors.push_back(_decode_ac(value, max_value * punch))

	var data := PackedByteArray()
	data.resize(width * height * 3)
	for y in range(height):
		for x in range(width):
			var r := 0.0
			var g := 0.0
			var b := 0.0

			for j in range(ny):
				for i in range(nx):
					var basics := cos((PI * x * i) / width) * cos((PI * y * j) / height)
					var idx := i + j * nx
					r += colors[idx].r * basics
					g += colors[idx].g * basics
					b += colors[idx].b * basics

			data[3 * (width * y + x)]     = int(clamp(_linear_to_srgb(r), 0, 255))
			data[3 * (width * y + x) + 1] = int(clamp(_linear_to_srgb(g), 0, 255))
			data[3 * (width * y + x) + 2] = int(clamp(_linear_to_srgb(b), 0, 255))

	var img := Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
	return ImageTexture.create_from_image(img)

## Returns whether the supplied BlurHash is valid.
func is_valid_blurhash(blurhash: String) -> bool:
	# Length must be 6 at minimum
	if blurhash.length() < 6:
		return false

	# Reported data must match with reported size
	var components := _from_base83(blurhash.substr(0, 1))
	var ny := (components / 9) + 1
	var nx := (components % 9) + 1

	return blurhash.length() == 4 + 2 * (nx * ny)

func _multiply_basis_func(component_x: int, component_y: int, width: int, height: int, data: PackedByteArray, format: int) -> Vector3:
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var normalization := 2 if (component_x | component_y) else 1
	var stride : int
	match format:
		Image.FORMAT_RGB8:
			stride = 3
		Image.FORMAT_RGBA8:
			stride = 4
	
	for y in range(height):
		for x in range(width):
			var basis := cos(PI * component_x * x / width) * cos(PI * component_y * y / height)
			r += basis * _srgb_to_linear(data[stride * (width * y + x)])
			g += basis * _srgb_to_linear(data[stride * (width * y + x) + 1])
			b += basis * _srgb_to_linear(data[stride * (width * y + x) + 2])
	
	var scale := normalization / float(width * height)
	print(r * scale)
	return Vector3(r * scale, g * scale, b * scale)

var _base83_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~"

func _from_base83(data: String) -> int:
	var value := 0
	for ch in data:
		var base83_val = _base83_chars.find(ch)
		if base83_val == -1:
			return -1
		else:
			value = value * 83 + base83_val
	return value

func _to_base83(value: int, num_chars: int) -> String:
	var data := ""
	var div = 1
	for i in range(num_chars - 1):
		div *= 83

	for i in range(num_chars):
		data += _base83_chars[(value / div) % 83]
		div /= 83

	return data

func _linear_to_srgb(value: float) -> int:
	var v = max(0, min(1, value))
	return int(v * 12.92 * 255 + 0.5 if v <= 0.0031308 else (1.055 * pow(v, 1 / 2.4) - 0.055) * 255 + 0.5)

func _srgb_to_linear(value: int) -> float:
	var v := value / 255.0
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)

func _sign_pow(value: float, expn: float) -> float:
	var result := pow(abs(value), expn)
	return -result if value < 0 else result

func _decode_dc(value: int) -> Color:
	return Color(
		_srgb_to_linear(value >> 16),
		_srgb_to_linear((value >> 8) & 255),
		_srgb_to_linear(value & 255)
	)

func _decode_ac(value: int, max_value: float) -> Color:
	var r := value / (19 * 19)
	var g := (value / 19) % 19
	var b := value % 19

	return Color(
		_sign_pow((r - 9.0) / 9, 2) * max_value,
		_sign_pow((g - 9.0) / 9, 2) * max_value,
		_sign_pow((b - 9.0) / 9, 2) * max_value
	)

func _encode_dc(color: Vector3) -> int:
	var r := _linear_to_srgb(color.x)
	var g := _linear_to_srgb(color.y)
	var b := _linear_to_srgb(color.z)
	return (r << 16) + (g << 8) + b

func _encode_ac(color: Vector3, max_value: float) -> int:
	var r := int(max(0, min(18, floor(_sign_pow(color.x / max_value, 0.5) * 9 + 9.5))))
	var g := int(max(0, min(18, floor(_sign_pow(color.y / max_value, 0.5) * 9 + 9.5))))
	var b := int(max(0, min(18, floor(_sign_pow(color.z / max_value, 0.5) * 9 + 9.5))))
	return r * 19 * 19 + g * 19 + b
