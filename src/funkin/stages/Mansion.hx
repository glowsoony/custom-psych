package funkin.stages;

class Mansion extends Stage {
	public function new() {
		super('mansion');
	}

	var bg:FunkinSprite;
	var flashingLight:FlxSprite;
	override function create():Void {
		super.create();

		bg = new FunkinSprite(-300, 0);
		if (Settings.data.reducedQuality) bg.loadGraphic(image('halloween_bg_low'));
		else {
			bg.frames = sparrowAtlas('halloween_bg');
			bg.animation.addByPrefix('d', 'halloweem bg', 0, false);
			bg.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
			bg.playAnim('d');
		}

		add(flashingLight = new FlxSprite(-800, -400));
		flashingLight.makeGraphic(1, 1, FlxColor.WHITE);
		flashingLight.scale.set(FlxG.width * 2, FlxG.height * 2);
		flashingLight.updateHitbox();
		flashingLight.alpha = 0;
		flashingLight.blend = ADD;

		addBehindObject(bg, game.gf);
	}

	var lastLightningBeat:Int = 0;
	var lightningOffset:Int = 8;
	override function beatHit(beat:Int) {
		if (beat < lastLightningBeat + lightningOffset) return;
		if (FlxG.random.bool(10)) lightningStrike(beat);
	}

	function lightningStrike(beat:Int) {
		FlxG.sound.play(sound('thunder_${FlxG.random.int(1, 2)}'));
		
		if (Settings.data.cameraZooms) {
			game.camGame.zoom += 0.015;
			game.camHUD.zoom += 0.03;

			FlxTween.tween(game.camGame, {zoom: game.defaultCamZoom}, 0.5);
			FlxTween.tween(game.camHUD, {zoom: 1}, 0.5);
		}

		if (!Settings.data.reducedQuality) bg.playAnim('lightning');

		if (Settings.data.flashingLights) {
			flashingLight.alpha = 0.4;
			FlxTween.tween(flashingLight, {alpha: 0.5}, 0.075);
			FlxTween.tween(flashingLight, {alpha: 0}, 0.25, {startDelay: 0.15});
		}

		// can't get special anims working i'll deal with it later lol
/*		if (game.bf.animation.exists('scared')) {
			game.bf.playAnim('scared');
			game.bf.specialAnim = true;
		}

		if (game.gf.animation.exists('scared')) {
			game.gf.playAnim('scared');
			game.gf.specialAnim = true;
		}

		if (game.dad.animation.exists('scared')) {
			game.dad.playAnim('scared');
			game.dad.specialAnim = true;
		}*/

		lastLightningBeat = beat;
		lightningOffset = FlxG.random.int(8, 24);
	}
}