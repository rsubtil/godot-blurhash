#include "blurhash.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/ref_counted.hpp>

using namespace godot;

void BlurHash::_bind_methods()
{
	ClassDB::bind_method(D_METHOD("is_valid_hash", "hash"), &BlurHash::is_valid_hash);
	ClassDB::bind_method(D_METHOD("encode", "texture", "xcomponents", "ycomponents"), &BlurHash::encode, DEFVAL(4), DEFVAL(3));
	ClassDB::bind_method(D_METHOD("decode", "hash", "width", "height", "punch"), &BlurHash::decode, DEFVAL(1));
}

BlurHash::BlurHash()
{
}

BlurHash::~BlurHash()
{
}

bool BlurHash::is_valid_hash(const String& p_hash) const
{
	return isValidBlurhash(p_hash.utf8().get_data());
}

String BlurHash::encode(const Ref<Texture2D>& p_texture, const int& p_xcomponents, const int& p_ycomponents) const
{
	Ref<Image> image = p_texture->get_image();
	switch(image->get_format()) {
		case Image::Format::FORMAT_RGB8:
		case Image::Format::FORMAT_RGBA8:
			break;
		default:
			// Unsupported
			return "";
	}
	int width = p_texture->get_width();
	int height = p_texture->get_height();
	const uint8_t* ptr = image->get_data().ptr();
	bool hasAlpha = image->get_format() == Image::Format::FORMAT_RGBA8;

	const char* hash = blurHashForPixels(p_xcomponents, p_ycomponents, width, height, ptr, hasAlpha);
	return String(hash);
}

Ref<Texture2D> BlurHash::decode(const String& p_hash, const int& p_width, const int& p_height, const int& p_punch) const
{
	if(!is_valid_hash(p_hash)) {
		return nullptr;
	}

	PackedByteArray data;
	data.resize(p_width * p_height * 3);
	decodeToArray(p_hash.utf8().get_data(), p_width, p_height, p_punch, 3, data.ptrw());
	Ref<Image> image = Image::create_from_data(p_width, p_height, false, Image::Format::FORMAT_RGB8, data);
	return ImageTexture::create_from_image(image);
}
