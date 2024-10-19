package objects;

import backend.animation.PsychAnimationController;
import flixel.system.FlxAssets.FlxShader;

private typedef NoteSplashAnim = {
	name:String,
	lane:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig = {
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowPixel:Bool
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	public var skin:String;
	public var config(default, set):NoteSplashConfig;

	public static var DEFAULT_SKIN:String = "noteSplashes/noteSplashes";
	public static var configs:Map<String, NoteSplashConfig> = new Map();

	public var babyArrow:StrumNote;
	var noteDataMap:Map<Int, String> = new Map();

	public function new(?splash:String) {
		super();

        animation = new PsychAnimationController(this);
		loadSplash(splash);
	}

	public function loadSplash(?splash:String) {
		config = null; // Reset config to the default so when reloaded it can be set properly
		skin = null;

		var skin:String = splash;
		if (skin == null || skin.length < 1)
			skin = try PlayState.SONG.splashSkin catch(e) null;

		if (skin == null || skin.length < 1)
			skin = DEFAULT_SKIN + getSplashSkinSuffix();

		this.skin = skin;

		try frames = Paths.getSparrowAtlas(skin) catch (e) {
			skin = DEFAULT_SKIN; // The splash skin was not found, return to the default
			this.skin = skin;
			try frames = Paths.getSparrowAtlas(skin) catch (e) {
				active = visible = false;
			}
		}

		var path:String = 'images/$skin.json';
		if (configs.exists(path)) this.config = configs.get(path);
		else if (Paths.fileExists(path, TEXT)) {
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile(path));
			if (config != null) {
				var tempConfig:NoteSplashConfig = {
					animations: new Map(),
					scale: config.scale,
					allowPixel: config.allowPixel
				}

				for (i in Reflect.fields(config.animations)) {
					tempConfig.animations.set(i, Reflect.field(config.animations, i));
				}

				this.config = tempConfig;
				configs.set(path, tempConfig);
			}
		}
	}

	public function spawnSplashNote(note:Note, ?lane:Null<Int>, ?randomize:Bool = true) {	
		if (note != null && note.noteSplashData.texture != null)
			loadSplash(note.noteSplashData.texture);

		if (note != null && note.noteSplashData.disabled)
			return;

		if (babyArrow != null)
			setPosition(babyArrow.x, babyArrow.y); // To prevent it from being misplaced for one game tick

		if (lane == null) lane = note.lane ?? 0;

		if (randomize) {
			var anims:Int = 0;
			var datas:Int = 0;
			var animArray:Array<Int> = [];

			while (true) {
				var data:Int = lane % Note.colArray.length + (datas * Note.colArray.length); 
				if (!noteDataMap.exists(data) || !animation.exists(noteDataMap[data])) break;

				datas++;
				anims++;
			}

			if (anims > 1) {
				for (i in 0...anims) {
					var data:Int = lane % Note.colArray.length + (i * Note.colArray.length);
					if (!animArray.contains(data))
						animArray.push(data);
				}
			}

			if (animArray.length > 1) lane = animArray[FlxG.random.bool() ? 0 : 1];
		}

		this.lane = lane;
		var anim:String = playDefaultAnim();

		var conf = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];

		if (conf != null)
			offsets = conf.offsets;

		if (offsets != null) {
			centerOffsets();
			offset.set(offsets[0], offsets[1]);
		}

		animation.finishCallback = function(name:String)
		{
			kill();
		};
		
        alpha = ClientPrefs.data.splashAlpha;
		if(note != null) alpha = note.noteSplashData.a;

		if (note != null) antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage) antialiasing = false;

		if(animation.curAnim != null && conf != null) {
			var minFps = conf.fps[0];
			if (minFps < 0) minFps = 0;

			var maxFps = conf.fps[1];
			if (maxFps < 0) maxFps = 0;

			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}
	
	public var lane:Int = 0;
	public function playDefaultAnim() {
		var animation:String = noteDataMap.get(lane);
		if (animation != null && this.animation.exists(animation)) this.animation.play(animation, true);
		else visible = false;
		return animation;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (babyArrow != null) {
			//cameras = babyArrow.cameras;
			setPosition(babyArrow.x, babyArrow.y);
		}
	}

    public static function getSplashSkinSuffix() {
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '-');
		return skin;
	}

	public static function createConfig():NoteSplashConfig {
		return {
			animations: new Map(),
			scale: 1,
			allowPixel: true
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, lane:Int):NoteSplashConfig {
		if (config == null) config = createConfig();

		config.animations.set(name, {name: name, lane: lane, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig  {
		if (value == null) value = createConfig();

		noteDataMap.clear();

		for (i in value.animations) {
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0) {
				if (i.indices != null && i.indices.length > 0 && key != null && key.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.lane, key);
			}
		}

		scale.set(value.scale, value.scale);
		return config = value;
	}
}

class PixelSplashShaderRef {
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var pixelAmount(default, set):Float = 1;

	public function set_pixelAmount(value:Float) {
		shader.uBlocksize.value = [value, value];
		return pixelAmount = value;
	}

	public function new() {
		pixelAmount = PlayState.isPixelStage ? PlayState.daPixelZoom : 1;
	}
}

class PixelSplashShader extends FlxShader {
	@:glFragmentHeader('
		#pragma header

		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			if (!hasTransform) return flixel_texture2D(bitmap, floor(coord * blocks) / blocks);

			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new() {
		super();
	}
}