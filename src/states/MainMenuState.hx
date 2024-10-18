package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import states.editors.MasterEditorMenu;
import options.OptionsState;

import objects.FunkinSprite;

class MainMenuState extends MusicBeatState {
	public static var curSelected:Int = 0;
	public static var mouseControls:Bool = true;

	var optionGrp:FlxTypedSpriteGroup<FunkinSprite>;
	var camFollow:FlxObject;

	final options:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	override function create() {
		super.create();

		persistentUpdate = true;

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		add(camFollow = new FlxObject(FlxG.width * 0.5, 0, 1, 1));

		var yScroll:Float = Math.max(0.25 - (0.05 * (options.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		add(optionGrp = new FlxTypedSpriteGroup<FunkinSprite>());

		// meth :broken_heart:
		var scr:Float = options.length < 6 ? 0 : (options.length - 4) * 0.135;
		var offset:Float = 108 - (Math.max(options.length, 4) - 4) * 80;
		for (i => option in options) {
			var item:FunkinSprite = createItem(option, 0, (i * 140) + offset);
			optionGrp.add(item);

			item.scrollFactor.set(0, scr);
			item.updateHitbox();
			item.screenCenter(X);
		}

		changeSelection();

		final versions:FlxText = new FlxText(4, 683, 0, 'Psych Engine v${Main.psychEngineVersion}\nFriday Night Funkin\' v${Main.baseGameVersion}', 16);
		versions.font = Paths.font('vcr.ttf');
		versions.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versions.scrollFactor.set();
		add(versions);

		FlxG.camera.follow(camFollow, null, 0.15);
		FlxG.mouse.visible = true;
	}

	var alreadyPressedEnter:Bool = false;
	override function update(elapsed:Float) {
		if (alreadyPressedEnter) {
			super.update(elapsed);
			return;
		}

		final downJustPressed:Bool = controls.UI_DOWN_P;
		if (downJustPressed || controls.UI_UP_P) changeSelection(downJustPressed ? 1 : -1);

		if (mouseControls && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)) {
			for (index => option in optionGrp.members) {
				if (!FlxG.mouse.overlaps(option) || curSelected == index) continue;

				changeSelection(index, true);
				break;
			}
		}

		if (controls.ACCEPT || (mouseControls && FlxG.mouse.overlaps(optionGrp.members[curSelected]) && FlxG.mouse.justPressed)) {
			alreadyPressedEnter = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			for (i => option in optionGrp.members) {
				if (i == curSelected) continue;

				FlxTween.tween(option, {alpha: 0}, 0.4, {
					ease: FlxEase.quadOut,
					onComplete: function(_) option.kill()
				});
			}

			FlxFlicker.flicker(optionGrp.members[curSelected], 1, 0.06, false, false, function(_) {
				switch (options[curSelected]) {
					case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
					case 'freeplay': MusicBeatState.switchState(new FreeplayState());

					#if MODS_ALLOWED
					case 'mods': MusicBeatState.switchState(new ModsMenuState());
					#end

					#if ACHIEVEMENTS_ALLOWED
					case 'awards': MusicBeatState.switchState(new AchievementsMenuState());
					#end

					case 'credits': MusicBeatState.switchState(new CreditsState());
					case 'options':
						MusicBeatState.switchState(new OptionsState());
						OptionsState.onPlayState = false;
						if (PlayState.SONG != null) {
							PlayState.SONG.arrowSkin = null;
							PlayState.SONG.splashSkin = null;
							PlayState.stageUI = 'normal';
						}
				}
			});
		}

		super.update(elapsed);
	}

	function createItem(option:String, x:Float, y:Float):FunkinSprite {
		final item:FunkinSprite = new FunkinSprite(x, y);
		item.scrollFactor.set();
		item.frames = Paths.getSparrowAtlas('mainmenu/menu_$option');
		item.animation.addByPrefix('idle', '$option idle', 24, true);
		item.animation.addByPrefix('selected', '$option selected', 24, true);
		item.playAnim('idle');

		return item;
	}

	function changeSelection(?dir:Int = 0, ?usingMouse:Bool = false) {
		var lastItem:FunkinSprite = optionGrp.members[curSelected];
		curSelected = usingMouse ? dir : FlxMath.wrap(curSelected + dir, 0, optionGrp.length - 1);
		var curItem:FunkinSprite = optionGrp.members[curSelected];

		lastItem.playAnim('idle');
		lastItem.updateHitbox();
		lastItem.screenCenter(X);

		curItem.playAnim('selected');
		curItem.centerOffsets();
		curItem.screenCenter(X);

		FlxG.sound.play(Paths.sound('scrollMenu'));
		camFollow.y = curItem.getGraphicMidpoint().y - (optionGrp.length > 4 ? optionGrp.length * 8 : 0);
	}
}
