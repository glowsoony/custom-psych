package funkin.objects;

class JudgementSpr extends FunkinSprite {
	var originalPos:FlxPoint;

	public function new(?x:Float, ?y:Float) {
		super(x, y);
		loadGraphic(Paths.image('judgements'), true, 400, 150);
		originalPos = FlxPoint.get(x, y);
		
		alpha = 0;
		acceleration.y = 550;

		moves = true;
		active = true;
		scale.set(0.7, 0.7);
		updateHitbox();
	}
	
	public function display(timing:Float) {
		if (Settings.data.judgementAlpha <= 0) return;
		
		setPosition(originalPos.x, originalPos.y);

		animation.frameIndex = Judgement.getIDFromTiming(timing);

		alpha = Settings.data.judgementAlpha;
		velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));

		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {alpha: 0}, 0.2, {startDelay: Conductor.crotchet * 0.001});
	}
}