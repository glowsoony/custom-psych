package objects;

import flixel.system.FlxAssets.FlxGraphicAsset;

class FunkinSprite extends flixel.FlxSprite {
	public var offsetMap:Map<String, Array<Float>> = [];

	public function new(?x:Float, ?y:Float, ?graphic:FlxGraphicAsset) {
		super(x, y, graphic);
		this.moves = false;
		this.active = false;
		this.antialiasing = Settings.data.antialiasing;

		this.animation.finishCallback = _ -> {
			this.active = false;
		}
	}

	// knew this was gonna get to me eventually lol
	override public function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):FunkinSprite {
		super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
		return this;
	}

	override public function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):FunkinSprite	{
		super.makeGraphic(width, height, color, unique, key);
		return this;
	}

	public function setOffset(name:String, offsets:Array<Float>) offsetMap.set(name, offsets);

	public function playAnim(name:String, ?forced:Bool = true) {
		if (!animation.exists(name)) {
			trace('Animation "$name" doesn\'t exist.');
			return;
		}

		final offsetsForAnim:Array<Float> = offsetMap.exists(name) ? offsetMap.get(name) : [0, 0];
		animation.play(name, forced);
		this.active = animation.curAnim.frames.length > 1;
		offset.set(offsetsForAnim[0], offsetsForAnim[1]);
	}
}