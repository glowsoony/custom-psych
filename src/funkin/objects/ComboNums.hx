package funkin.objects;

import flixel.group.FlxSpriteGroup;

using flixel.util.FlxColorTransformUtil;

class ComboNums extends FlxTypedSpriteGroup<Number> {
	public static final default_startingDigits:Int = 3;
	public function new(?x:Float, ?y:Float) {
		super(x, y);
		for (i in 0...default_startingDigits) insert(0, new Number());
		scale.set(0.5, 0.5);
	}

	public function display(comboNum:Int) {
		if (Settings.data.comboAlpha <= 0) return;

		final comboStr:String = '$comboNum'.lpad('0', default_startingDigits);

		// remove any excess numbers
		while (length > comboStr.length) remove(members[0], true);

		// then add any new ones
		for (_ in 0...comboStr.length - length) insert(0, new Number());

		for (i in 0...comboStr.length) {
			final num:Number = members[i];
			if (num == null) continue;

			final convertedNum:Int = Std.parseInt(comboStr.charAt(i));

			if (num.animation.frameIndex != convertedNum) num.animation.frameIndex = convertedNum;
			num.scale.set(scale.x, scale.y);
			num.updateHitbox();
			num.setPosition(x + ((num.frameWidth * i) * scale.x), y);
			num.velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));
			num.visibility = Settings.data.comboAlpha;

			FlxTween.cancelTweensOf(num);
			FlxTween.tween(num, {visibility: 0}, 0.2, {
				onComplete: function(_) num.visibility = 0,
				startDelay: Conductor.crotchet * 0.001
			});
		}
	}
}

private class Number extends FunkinSprite {
	// using this instead of `alpha`
	// so you can set the `alpha` variable without fucking up anything
	public var visibility(default, set):Float = 1;
	function set_visibility(v:Float):Float {
		if (visibility == v) return v;

		visibility = FlxMath.bound(v, 0, 1);
		updateColorTransform();
		return visibility;
	}

	public function new() {
		super();

		loadGraphic(Paths.image('comboNums'), true, 95, 115);
		acceleration.y = 550;
		visibility = 0;

		active = true;
		moves = true;
	}

	override function destroy() {
		FlxTween.cancelTweensOf(this);
		super.destroy();
	}

	override function draw():Void {
		if (visibility <= 0) return;

		super.draw();
	}

	override function updateColorTransform():Void {
		if (colorTransform == null) return;

		useColorTransform = alpha != 1 || visibility != 1 || color != 0xffffff;
		if (useColorTransform) this.colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, visibility * alpha);
		else this.colorTransform.setMultipliers(1, 1, 1, 1);

		dirty = true;
	}
}