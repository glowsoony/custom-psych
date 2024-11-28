package options;

import states.MainMenuState;

class OptionsState extends MusicState
{
	var options:Array<String> = [
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch (label) {
			case 'Controls':
				openSubstate(new options.ControlsSubState());
			case 'Graphics':
				openSubstate(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubstate(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubstate(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicState.switchState(new options.NoteOffsetState());
			case 'Language':
				openSubstate(new options.LanguageSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/desatBG'));
		bg.antialiasing = Settings.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(200, 0, Language.getPhrase('options_$option', option), BOLD, CENTER);
			optionText.screenCenter(Y);
			optionText.y += (92 * (num - (options.length / 2))) + 45;
			grpOptions.add(optionText);
		}

		add(selectorLeft = new Alphabet(0, 0, '>', BOLD));
		add(selectorRight = new Alphabet(0, 0, '<', BOLD));

		changeSelection();
		Settings.save();

		super.create();
	}

	override function closeSubstate() {
		super.closeSubstate();
		Settings.save();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		final upJustPressed:Bool = Controls.justPressed('ui_up');
		if (upJustPressed || Controls.justPressed('ui_down')) changeSelection(upJustPressed ? -1 : 1);

		if (Controls.justPressed('back')) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (onPlayState) {
				MusicState.switchState(new PlayState());
				FlxG.sound.music.volume = 0;
			} else MusicState.switchState(new MainMenuState());
		} else if (Controls.justPressed('accept')) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy() {
		Settings.load();
		super.destroy();
	}
}