package states;

import backend.WeekData;
import flixel.graphics.FlxGraphic;

class StoryMenuState extends MusicState {
	var grpWeeks:FlxTypedSpriteGroup<WeekSprite>;
	var difficultyList:Array<Array<String>> = [];
	var bgSprite:FlxSprite;

	var tracksSprite:FlxSprite;
	var tracklist:FlxText;

	var diffSprite:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	static var curWeek:Int = 0;
	static var curDifficulty:Int;
	static var curDiffName:String = Difficulty.current;
	static var curDiffs:Array<String> = Difficulty.list;

	override function create():Void {
		super.create();

		WeekData.reload();
		if (curWeek >= WeekData.list.length) curWeek = 0;

		add(grpWeeks = new FlxTypedSpriteGroup<WeekSprite>());

		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		add(bgYellow);

		bgSprite = new FlxSprite(bgYellow.x, bgYellow.y);

		var itemTargetY:Float = 0;
		for (index => week in WeekData.list) {
			var weekSprite:WeekSprite = new WeekSprite(week.fileName);
			weekSprite.screenCenter(X);
			weekSprite.y = (bgSprite.y + 396) + ((weekSprite.height + 20) * index);
			weekSprite.targetY = itemTargetY;
			grpWeeks.add(weekSprite);

			itemTargetY += Math.max(weekSprite.height, 110) + 10;

			difficultyList.push(Difficulty.loadFromWeek(week));
		}

		tracksSprite = new FlxSprite(0, bgSprite.y + 425).loadGraphic(Paths.image('menus/story/tracks'));
		tracksSprite.antialiasing = Settings.data.antialiasing;
		tracksSprite.x = 190 - (tracksSprite.width * 0.5);
		add(tracksSprite);

		add(tracklist = new FlxText(0, tracksSprite.y + 60, 0, '', 32));
		tracklist.alignment = CENTER;
		tracklist.font = Paths.font('vcr.ttf');
		tracklist.color = 0xFFE55777;

		leftArrow = new FlxSprite(850, 462);
		leftArrow.antialiasing = Settings.data.antialiasing;
		leftArrow.frames = Paths.sparrowAtlas('menus/story/ui');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		add(leftArrow);
		
		diffSprite = new FlxSprite(0, leftArrow.y);
		diffSprite.antialiasing = Settings.data.antialiasing;
		add(diffSprite);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = Settings.data.antialiasing;
		rightArrow.frames = Paths.sparrowAtlas('menus/story/ui');
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		add(rightArrow);

		changeWeek();
	}

	function changeWeek(?change:Int = 0) {
		curWeek = FlxMath.wrap(curWeek + change, 0, grpWeeks.length - 1);

		for (index => sprite in grpWeeks.members) {
			sprite.alpha = curWeek == index ? 1 : 0.5;
		}

		var tracks:String = '';
		var songList:Array<Track> = WeekData.list[curWeek].songs;
		for (index => song in songList) {
			tracks += song.id.toUpperCase();
			if (index != songList.length - 1) tracks += '\n';
		}

		tracklist.text = tracks;
		tracklist.x = tracksSprite.getGraphicMidpoint().x - (tracklist.width * 0.5);

		FlxG.sound.play(Paths.sound('scroll'));

		curDiffs = difficultyList[curWeek];

		curDifficulty = curDiffs.indexOf(curDiffName);
		if (curDifficulty == -1) curDifficulty = 0;
		changeDifficulty();
	}

	function changeDifficulty(?change:Int = 0) {
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, curDiffs.length - 1);
		curDiffName = curDiffs[curDifficulty];

		var newImage:FlxGraphic = Paths.image('difficulties/${Difficulty.format(curDiffName)}');

		if (diffSprite.graphic != newImage) {
			diffSprite.loadGraphic(newImage);
			diffSprite.x = leftArrow.x + 60;
			diffSprite.x += (308 - diffSprite.width) / 3;
			diffSprite.alpha = 0;
			diffSprite.y = leftArrow.y - diffSprite.height + 50;

			FlxTween.cancelTweensOf(diffSprite);
			FlxTween.tween(diffSprite, {y: diffSprite.y + 30, alpha: 1}, 0.07);
		}
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeWeek(downJustPressed ? 1 : -1);
		}

		final leftJustPressed:Bool = Controls.justPressed('ui_left');
		if (leftJustPressed || Controls.justPressed('ui_right')) changeDifficulty(leftJustPressed ? -1 : 1);
		
		leftArrow.animation.play(Controls.pressed('ui_left') ? 'press' : 'idle');
		rightArrow.animation.play(Controls.pressed('ui_right') ? 'press' : 'idle');

		var offsetY:Float = grpWeeks.members[curWeek].targetY;
		for (_ => item in grpWeeks.members)
			item.y = FlxMath.lerp(item.targetY - offsetY + 480, item.y, Math.exp(-elapsed * 10.2));

		if (Controls.justPressed('back')) MusicState.switchState(new MainMenuState());
	}
}

private class WeekSprite extends FlxSprite {
	public var targetY:Float;

	public function new(name:String) {
		super();
		loadGraphic(Paths.image('menus/story/$name'));
	}	
}