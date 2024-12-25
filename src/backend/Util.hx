package backend;

class Util {
	inline public static function quantize(f:Float, snap:Float):Float {
		return Math.fround(f * snap) / snap;
	}

    public static function ilerp(from:Float, to:Float, weight:Float):Float {
		return from + FlxMath.bound(weight * 60 * FlxG.elapsed, 0, 1) * (to - from);
    }

	public static function isLetter(c:String) { // thanks kade
		var ascii:Int = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90)
			|| (ascii >= 97 && ascii <= 122)
			|| (ascii >= 192 && ascii <= 214)
			|| (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	inline public static function listFromString(string:String):Array<String> {
		return string.trim().split('\n');
	}

	// FlxStringUtil.formatBytes() but it just adds a space between the size and the unit lol
	public static function formatBytes(bytes:Float, ?precision:Int = 2):String {
		final units:Array<String> = ["Bytes", "KB", "MB", "GB", "TB", "PB"];
		var curUnit:Int = 0;
		while (bytes >= 1024 && curUnit < units.length - 1) {
			bytes /= 1024;
			curUnit++;
		}

		return '${FlxMath.roundDecimal(bytes, precision)} ${units[curUnit]}';
	}

	inline public static function capitalize(text:String):String {
		return '${text.charAt(0).toUpperCase()}${text.substr(1).toLowerCase()}';
	}

	public static function mean(values:Array<Float>):Float {
		final amount:Int = values.length;
		var result:Float = 0.0;

		var value:Float = 0;
		for (i in 0...amount) {
			value = values[i];
			if (value == 0) continue;
			result += value;
		}

		return result / amount;
	}

	public static function colorFromString(color:String):FlxColor {
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color) ?? FlxColor.fromString('#$color');
		return colorNum ?? FlxColor.WHITE;
	}

	public static function truncateFloat(number:Float, precision:Float = 2):Float {
		number *= (precision = Math.pow(10, precision));
		return Math.floor(number) / precision;
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

	public static function openURL(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function openFolder(folder:String, ?absolute:Bool = false) {
		#if sys
		if (!absolute) folder = '${Sys.getCwd()}$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/')) folder.substr(0, folder.length - 1);

		Sys.command(#if linux '/usr/bin/xdg-open' #else 'explorer.exe' #end, [folder]);
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

	public static function getOperatingSystem():String {
		#if windows
		return 'Windows';
		#elseif linux
		return 'Linux';
		#elseif (mac || macos)
		return 'macOS';
		#else
		return 'Unknown';
		#end
	}

	public static function getTarget():String {
		#if cpp
		return 'C++';
		#elseif hl
		return 'Hashlink';
		#else
		return 'Unknown';
		#end
	}

	// wife3 calc stuff
	// you can ignore all of this

    public static final wife3MissWeight:Float = -5.5;
    public static final wife3MineWeight:Float = -7;
    public static final wife3HoldDropWeight:Float = -4.5;
    
    static inline final a1:Float = 0.254829592;
    static inline final a2:Float = -0.284496736;
    static inline final a3:Float = 1.421413741;
    static inline final a4:Float = -1.453152027;
    static inline final a5:Float = 1.061405429;
    static inline final p:Float = 0.3275911;

    public static function werwerwerwerf(x:Float):Float {
        var neg = x < 0;
        x = Math.abs(x);
        var t = 1 / (1 + p * x);
        var y = 1 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);
        return neg ? -y : y;
    }

    public static var timeScale:Float = 1;
    public static function wife3(noteDiff:Float, ?ts:Float):Float { // https://github.com/etternagame/etterna/blob/0a7bd768cffd6f39a3d84d76964097e43011ce33/src/RageUtil/Utils/RageUtil.h
        ts ??= timeScale;
        if(ts > 1) ts = 1;
        var jPow:Float = 0.75;
        var maxPoints:Float = 2.0;
        var ridic:Float = 5 * ts;
        var shit_weight:Float = 200;
        var absDiff = Math.abs(noteDiff);
        var zero:Float = 65 * Math.pow(ts, jPow);
        var dev:Float = 22.7 * Math.pow(ts, jPow);

        if (absDiff <= ridic) return maxPoints;
        else if (absDiff <= zero) return maxPoints * werwerwerwerf((zero - absDiff) / dev);
        else if (absDiff <= shit_weight) return (absDiff - zero) * wife3MissWeight / (shit_weight - zero);

        return wife3MissWeight;
    }
}