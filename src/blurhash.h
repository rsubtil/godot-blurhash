#ifndef BLURHASH_H
#define BLURHASH_H

#include <godot_cpp/core/object.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/variant/string.hpp>

extern "C" {
#include "algorithm/decode.h"
#include "algorithm/encode.h"
}

namespace godot
{
	class BlurHash : public Object
	{
		GDCLASS(BlurHash, Object)

	private:
		static BlurHash *singleton;

	protected:
		static void _bind_methods();

	public:
		bool is_valid_hash(const String& hash) const;
		String encode(const Ref<Texture2D>& p_texture, const int& p_xcomponents = 4, const int& p_ycomponents = 3) const;
		Ref<Texture2D> decode(const String& p_hash, const int& p_width, const int& p_height, const int& p_punch = 1) const;

		static BlurHash *get_singleton() { return singleton; }

		BlurHash();
		~BlurHash();
	};
}

#endif // BLURHASH_H