package funkin.backend;

import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;

import crowplexus.iris.Iris;
import crowplexus.iris.ErrorSeverity;

class Debug extends FlxTypedGroup<DebugText> {
	public static var self(default, null):Debug;

	public function new() {
		super();
		self = this;
		this.active = false;

		Iris.logLevel = function(severity, v, ?pos) {
			switch severity {
				// just normal trace();
				case NONE:
					var fileName:String = pos.fileName;
					var line:Int = pos.lineNumber;

					Sys.println('$fileName:$line: $v');
					printMessage(v);

				// basically TraceFunctions.hx but copypasted so it uses fileName instead of className
				case WARN:
					var fileName:String = pos.fileName;
					var line:Int = pos.lineNumber;

					print('${INVERT.format(33)}[WARNING | $fileName:$line]${INIT.format()} $v', pos);
					printMessage('[WARNING | $fileName:$line] $v', WARN);

				case ERROR:
					var fileName:String = pos.fileName;
					var line:Int = pos.lineNumber;

					print('${INVERT.format(31)}[ERROR | $fileName:$line]${INIT.format()} $v', pos);
					printMessage('[ERROR | $fileName:$line] $v', ERROR);

				case FATAL:
					var fileName:String = pos.fileName;
					var line:Int = pos.lineNumber;

					print('${DIM.format(31)}[FATAL | $fileName:$line]${INIT.format()} $v', pos);
					printMessage('[FATAL | $fileName:$line] $v', FATAL);
			}
		}
	}

	public static function printMessage(message:String, ?severity:ErrorSeverity) {
		if (self == null) return;

		var invertedBorder:Bool = false;
		var textColour:FlxColour = switch severity {
			case WARN: 
				//invertedBorder = true;
				0xFFC4A000;
			case ERROR: 
				//invertedBorder = true;
				0xFFFF0000;
			case FATAL: 
				//invertedBorder = true;
				0xFFCC0000;
			default: 0xFFFFFFFF;
		}

		if (self.length != 0) {
			for (obj in self.members) {
				if (obj == null) continue;
				obj.y += 16;
			}
		}

		var txt:DebugText = self.add(new DebugText(message, textColour));

		// i hate this game engine
		txt.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		txt.borderColor = invertedBorder ? FlxColour.WHITE : FlxColour.BLACK;

		new FlxTimer().start(2, function(_) {
			if (txt == null) return;

			FlxTween.tween(txt, {alpha: 0}, 1, {onComplete: function(_) {
				self.remove(txt);
				txt.destroy();
				txt = null;
			}});
		});
	}

	public static function clean():Void {
		for (text in self.members) {
			if (text == null) continue;

			FlxTween.cancelTweensOf(text);	
		}

		self.clear();
	}
}

private class DebugText extends flixel.text.FlxText {
	public function new(message:String, ?color:Int = 0xFFFFFFFF) {
		super(0, 0, FlxG.width, message, 16);
		active = false;
		moves = false;
		this.color = color;
		font = Paths.font('vcr.ttf');

		scrollFactor.set();
		borderSize = 1.25;
		borderStyle = FlxTextBorderStyle.OUTLINE;
	}
}