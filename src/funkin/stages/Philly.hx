package funkin.stages;

class Philly extends Stage {
	public function new() {
		super('philly');
	}

	var window:FunkinSprite;
	var street:FunkinSprite;
	//var train:PhillyTrain;

	var windowColours:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	var colourIndex:Int = 0;

	override function create():Void {
		super.create();

		if (!Settings.data.reducedQuality) {
			var sky:FunkinSprite = new FunkinSprite(-100, 0, image('sky'));
			sky.scrollFactor.set(0.1, 0.1);
			addBehindObject(sky, game.gf);
		}

		var city:FunkinSprite = new FunkinSprite(-10, 0, image('city'));
		city.scrollFactor.set(0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		addBehindObject(city, game.gf);

		addBehindObject(window = new FunkinSprite(city.x, city.y, image('window')), game.gf);
		window.scrollFactor.set(0.3, 0.3);
		window.setGraphicSize(Std.int(window.width * 0.85));
		window.updateHitbox();
		window.alpha = 0;
		
		if (!Settings.data.reducedQuality) {
			addBehindObject(new FunkinSprite(-40, 50, image('behindTrain')), game.gf);
		}

		//addBehindObject(train = new PhillyTrain(2000, 360));

		addBehindObject(street = new FunkinSprite(-40, 50, image('street')), game.gf);
	}

	override function measureHit(measure:Int):Void {
		colourIndex = FlxG.random.int(0, windowColours.length - 1, [colourIndex]);
		window.color = windowColours[colourIndex];
		window.alpha = 1;
	}

	override function update(delta:Float):Void {
		if (window.alpha > 0) window.alpha -= (Conductor.crotchet * 0.001) * delta * 1.5;
	}
}