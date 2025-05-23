package funkin.states;

import funkin.objects.MenuCharacter;
import flixel.graphics.FlxGraphic;

class StoryMenuState extends MusicState {
	var bgSprite:FlxSprite;
	var tracksSprite:FlxSprite;
	var tracklist:FlxText;

	var diffSprite:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	// seperate array because of `hideStoryMode`
	var weekList:Array<WeekFile> = [];

	var curWeekFile(get, never):WeekFile;
	function get_curWeekFile():WeekFile return weekList[curSelected];

	var curDiffName(get, never):String;
	function get_curDiffName():String return curWeekFile.difficulties[curDiffSelected];

	var weekSprGroup:FlxTypedSpriteGroup<WeekSprite>;
	var characters:FlxTypedSpriteGroup<MenuCharacter>;
	var curSelected:Int = 0;
	var curDiffSelected:Int = 0;

	override function create():Void {
		super.create();

		add(weekSprGroup = new FlxTypedSpriteGroup<WeekSprite>());
			
		// this is really dumb but whatever
		add(new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK));

		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		add(bgYellow);

		add(bgSprite = new FlxSprite(bgYellow.x, bgYellow.y));

		add(characters = new FlxTypedSpriteGroup<MenuCharacter>());
		for (i in 1...4) {
			characters.add(new MenuCharacter((FlxG.width - 960) * i - 150, 70));
		}

		add(tracksSprite = new FlxSprite(0, bgSprite.y + 425).loadGraphic(Paths.image('menus/story/tracks')));
		tracksSprite.antialiasing = Settings.data.antialiasing;
		tracksSprite.x = 190 - (tracksSprite.width * 0.5);

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

		reload();
	}

	var allowInput:Bool = true;
	override function update(delta:Float):Void {
		super.update(delta);

		var offsetY:Float = weekSprGroup.members[curSelected].targetY;
		for (item in weekSprGroup.members)
			item.y = FlxMath.lerp(item.targetY - offsetY + 480, item.y, Math.exp(-delta * 10.2));

		if (!allowInput) return;

		if (Controls.justPressed('back')) MusicState.switchState(new MainMenuState());

		var justPressedUp:Bool = Controls.justPressed('ui_up');
		if (justPressedUp || Controls.justPressed('ui_down')) changeSelection(justPressedUp ? -1 : 1);

		var leftJustPressed:Bool = Controls.justPressed('ui_left');
		if (leftJustPressed || Controls.justPressed('ui_right')) changeDifficulty(leftJustPressed ? -1 : 1);

		if (Controls.justPressed('accept')) {
			allowInput = false;
			FlxG.sound.play(Paths.sound('confirm'));

			for (char in characters.members) {
				if (char.name == '' || !char.hasConfirmAnimation) continue;
				char.animation.play('confirm');
			}

			PlayState.songList = [for (song in curWeekFile.songs) song.name];
			PlayState.storyMode = true;

			Difficulty.list = curWeekFile.difficulties;
			Difficulty.current = curDiffName;

			new FlxTimer().start(1, function(_) MusicState.switchState(new PlayState()));
		}

		leftArrow.animation.play(Controls.pressed('ui_left') ? 'press' : 'idle');
		rightArrow.animation.play(Controls.pressed('ui_right') ? 'press' : 'idle');
	}

	function changeDifficulty(?dir:Int = 0) {
		curDiffSelected = FlxMath.wrap(curDiffSelected + dir, 0, curWeekFile.difficulties.length - 1);

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

	function changeSelection(?dir:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + dir, 0, weekSprGroup.length - 1);

		for (index => sprite in weekSprGroup.members) {
			sprite.alpha = curSelected == index ? 1 : 0.5;
		}

		var tracks:String = '';
		var songList:Array<Track> = curWeekFile.songs;
		for (index => song in songList) {
			tracks += song.name.toUpperCase();
			if (index != songList.length - 1) tracks += '\n';
		}

		tracklist.text = tracks;
		tracklist.x = tracksSprite.getGraphicMidpoint().x - (tracklist.width * 0.5);

		for (index => item in characters.members) {
			item.name = curWeekFile.characters[index];
		}
		
		curDiffSelected = curWeekFile.difficulties.indexOf(curDiffName);
		if (curDiffSelected == -1) curDiffSelected = 0;
		changeDifficulty();
	}

	function reload():Void {
		WeekData.reload();
		if (curSelected >= WeekData.list.length) curSelected = 0;

		weekSprGroup.clear();
		weekList.resize(0);

		var itemTargetY:Float = 0;
		var index:Int = 0;
		for (week in WeekData.list) {
			if (week.hideStoryMode) continue;

			weekList.push(week);

			var weekSprite:WeekSprite = new WeekSprite(week.fileName);
			weekSprite.screenCenter(X);
			weekSprite.y = (bgSprite.y + 396) + ((weekSprite.height + 20) * index);
			weekSprite.targetY = itemTargetY;
			weekSprGroup.add(weekSprite);

			itemTargetY += Math.max(weekSprite.height, 110) + 10;

			++index;
		}

		changeSelection();
	}
}

private class WeekSprite extends FlxSprite {
	public var targetY:Float;

	public function new(name:String) {
		super();
		loadGraphic(Paths.image('menus/story/$name'));
	}	
}