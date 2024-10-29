package backend;

class Util {
	inline public static function quantize(f:Float, snap:Float):Float {
		return Math.fround(f * snap) / snap;
	}

	inline public static function listFromString(string:String):Array<String> {
		return string.trim().split('\n');
	}

	inline public static function capitalize(text:String):String {
		return '${text.charAt(0).toUpperCase()}${text.substr(1).toLowerCase()}';
	}

	public static function coolTextFile(path:String):Array<String> {
		var file:String = FileSystem.exists(path) ? File.getContent(path) : null;
		return file != null ? listFromString(file) : [];
	}

	inline public static function colorFromString(color:String):FlxColor {
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color) ?? FlxColor.fromString('#$color');
		return colorNum ?? FlxColor.WHITE;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float {
		if (decimals < 1) return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals) tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int {
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel.alphaFloat < 0.05) continue;
	
				colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
				var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
				countByColor[colorOfThisPixel] = count + 1;
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key => count in countByColor) {
			if (count <= maxCount) continue;
			maxCount = count;
			maxKey = key;
		}

		countByColor.clear();
		return maxKey;
	}

	inline public static function openURL(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
		if (!absolute) folder = '${Sys.getCwd()}$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/')) folder.substr(0, folder.length - 1);

		var command:String = #if linux '/usr/bin/xdg-open'; #else 'explorer.exe'; #end
		Sys.command(command, [folder]);
		#else
		FlxG.error("Platform is not supported for Util.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		final file:String = FlxG.stage.application.meta.get('file');

		return '${company}/${flixel.util.FlxSave.validate(file)}';
	}
}
