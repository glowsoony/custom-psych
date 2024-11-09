package backend;

import flixel.graphics.FlxGraphic;
import openfl.system.System;

import lime.utils.Assets as LimeAssets;
import openfl.media.Sound;

import openfl.display.BitmapData;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;

// credits to Chris Speciale (lead openfl maintainer) for giving me this abstract lmao
// was a pain in the ass to deal with Dynamic
abstract CachedAsset(Dynamic) {
    // cast from FlxGraphic to CachedAsset
    @:from static inline function fromFlxGraphic(graphic:FlxGraphic):CachedAsset {
        return cast graphic;
    }
    // cast from Sound to CachedAsset
    @:from static inline function fromSound(sound:Sound):CachedAsset {
        return cast sound;
    }
    // cast from CachedAsset to FlxGraphic
    @:to inline function toFlxGraphic():FlxGraphic {
        return cast this;
    }

    // cast from CachedAsset to Sound
    @:to inline function toSound():Sound {
        return cast this;
    }
}

class Paths {
	public static final SOUND_EXT:String = "ogg";
	public static final VIDEO_EXT:String = "mp4";
	public static final IMAGE_EXT:String = "png";

	public static final dumpExclusions:Array<String> = ['assets/music/freakyMenu.$SOUND_EXT'];

	// the tracked assets for the current state
	// not meant to be iterated through for all assets loaded
	public static var localTrackedAssets:Array<String> = [];

	// the currently cached assets
	// iterate this if you want all assets currently loaded
	public static var cachedAssets:Map<String, CachedAsset> = [];

	inline public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static function destroyAsset(key:String, ?asset:CachedAsset) {
		if (asset == null) {
			asset = cachedAssets[key];
			if (asset == null) return;
		}

		switch (Type.typeof(asset)) {
			// destroying method for graphics
			case TClass(FlxGraphic):
				var graphic:FlxGraphic = asset;

				@:privateAccess
				if (graphic.bitmap != null && graphic.bitmap.__texture != null)
					graphic.bitmap.__texture.dispose();
				FlxG.bitmap.remove(graphic);

				graphic = null;
			// destroying method for sounds
			case TClass(Sound):
				(asset:Sound).close();
				LimeAssets.cache.clear(key);

			// if grabbed asset doesn't exist then we stop the function
			default:
				trace('uh oh failed asset !!!!! "$key"');
				return;
		}

		cachedAssets.remove(key);
	}

	// deload unused assets from memory
	public static function clearUnusedMemory() {
		for (key => asset in cachedAssets) {
			if (localTrackedAssets.contains(key) || dumpExclusions.contains(key)) continue;	
			destroyAsset(key, asset);
		}

		System.gc();
	}

	// clear all assets from memory
	public static function clearStoredMemory() {
		for (key => asset in cachedAssets) {
			if (dumpExclusions.contains(key)) continue;
			destroyAsset(key, asset);
		}

		localTrackedAssets = [];
		System.gc();
	}

	public static function get(path:String, ?subFolder:String):String {
		if (subFolder == null || subFolder.length == 0) return 'assets/$path';

		return 'assets/$subFolder/$path';
	}

	// images
	public static function image(key:String, ?subFolder:String = 'images', ?allowGPU:Bool = true):FlxGraphic {
		allowGPU = Settings.data.cacheOnGPU ? allowGPU : false;

		key = Language.getFileTranslation(key, subFolder);
		if (key.lastIndexOf('.') < 0) key += '.$IMAGE_EXT';

		if (cachedAssets.exists(key)) return cachedAssets.get(key);
		if (!FileSystem.exists(key)) return null;
		if (!localTrackedAssets.contains(key)) localTrackedAssets.push(key);

		return cacheBitmap(key, BitmapData.fromFile(key), allowGPU);
	}

	public static function cacheBitmap(key:String, bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic {
		if (allowGPU && bitmap.image != null) {
			@:privateAccess
			if (bitmap.__texture == null) {
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
	
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;

			@:privateAccess {
				bitmap.image = null;
				bitmap.readable = true;
			}
		}

		final graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		cachedAssets.set(key, graph);
		
		return graph;
	}

	public static function exists(path:String):Bool {
		return FileSystem.exists(get(path));
	}

	// basically sys.io.File.getContent() but a failsafe if the file doesn't exist
	public static function getFileContent(path:String):String {
		path = get(path);
		if (!FileSystem.exists(path)) return '';

		return File.getContent(path);
	}

	public static function audio(key:String, ?subFolder:String, ?beepIfNull:Bool = true):Sound {
		key = Language.getFileTranslation(key, subFolder);
		if (key.lastIndexOf('.') < 0) key += '.$SOUND_EXT';

		var file:Sound = null;

		if (cachedAssets.exists(key)) return cachedAssets.get(key);
		if (!FileSystem.exists(key)) {
			return beepIfNull ? flixel.system.FlxAssets.getSound('flixel/sounds/beep') : null;
		}
		if (!localTrackedAssets.contains(key)) localTrackedAssets.push(key);

		file = Sound.fromFile(key);
		cachedAssets.set(key, file);

		return file;
	}

	// shortcut for `Paths.audio('m', 'music');
	public static function music(key:String, ?subFolder:String = 'music', ?beepIfNull:Bool = true) {
		return audio(key, subFolder, beepIfNull);
	}

	// shortcut for `Paths.audio('m', 'sounds');
	public static function sound(key:String, ?subFolder:String = 'sounds', ?beepIfNull:Bool = true) {
		return audio(key, subFolder, beepIfNull);
	}

	public static function font(path:String, ?subFolder:String = 'fonts'):String {
		return get(path, subFolder);
	}

	public static function text(path:String, ?subFolder:String = 'data'):String {
		return get(path, subFolder);
	}

	static public function getMultiAtlas(keys:Array<String>, ?subFolder:String = null):FlxAtlasFrames {
		var parentFrames:FlxAtlasFrames = cast Paths.sparrowAtlas(keys[0].trim());
		if (keys.length < 1) return parentFrames;

		var original:FlxAtlasFrames = parentFrames;
		parentFrames = new FlxAtlasFrames(parentFrames.parent);
		parentFrames.addAtlas(original, true);
		for (i in 1...keys.length) {
			var extraFrames:FlxAtlasFrames = cast Paths.sparrowAtlas(keys[i].trim(), subFolder);
			if (extraFrames != null) parentFrames.addAtlas(extraFrames, true);
		}

		return parentFrames;
	}

	public static function sparrowAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		final dataFile:String = get('$path.xml', subFolder);
		if (!FileSystem.exists(dataFile)) return null;

		return FlxAtlasFrames.fromSparrow(image(path, subFolder), File.getContent(dataFile));
	}

	public static function packerAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		final dataFile:String = get('$path.txt', subFolder);
		if (!FileSystem.exists(dataFile)) return null;

		return FlxAtlasFrames.fromSpriteSheetPacker(image(path, subFolder), File.getContent(dataFile));
	}

	public static function asepriteAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		final dataFile:String = get('$path.json', subFolder);
		if (!FileSystem.exists(dataFile)) return null;

		return FlxAtlasFrames.fromTexturePackerJson(image(path, subFolder), File.getContent(dataFile));
	}
}