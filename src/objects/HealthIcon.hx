package objects;

import flixel.graphics.FlxGraphic;

class HealthIcon extends FlxSprite {
	public var character:String = '';
	var isPlayer:Bool = false;
	var iconOffsets:Array<Float> = [0.0, 0.0];

	public function new(?char:String = 'face', ?isPlayer:Bool = false, ?allowGPU:Bool = true) {
		super();
		this.isPlayer = isPlayer;
		change(char, allowGPU);
	}

	function change(name:String, ?allowGPU:Bool = true):String {
		if (character == name) return name;

		if (!Paths.exists('images/icons/$name.png')) name = 'face';
		var graphic:FlxGraphic = Paths.image('icons/$name', allowGPU);

		var size:Float = Math.round(graphic.width / graphic.height);
		loadGraphic(graphic, true, Math.floor(graphic.width / size), Math.floor(graphic.height));
		iconOffsets = [(width - 150) / size, (height - 150) / size];
		updateHitbox();

		animation.add(name, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
		animation.play(name);
		
		antialiasing = name.endsWith('-pixel') ? false : Settings.data.antialiasing;

		return this.character = name;
	}

	public var autoOffset:Bool = true;
	override function updateHitbox() {
		super.updateHitbox();

		if (!autoOffset) return;
		offset.set(iconOffsets[0], iconOffsets[1]);
	}
}
