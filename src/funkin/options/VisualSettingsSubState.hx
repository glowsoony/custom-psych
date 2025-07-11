package funkin.options;

import funkin.objects.Note;

class VisualSettingsSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('visuals_menu', 'Visual Settings');
		rpcTitle = 'Visual Settings Menu';
		
		addOption(new Option(
			'Flashing Lights',
			'Self explanatory.',
			'flashingLights',
			BOOL
		));

		addOption(new Option(
			'Judgement Counter',
			'Adds a counter to the left side of your screen\nthat counts how many judgements you\'ve hit.',
			'judgementCounter',
			BOOL
		));

		addOption(new Option(
			'Glow Animation On Note Hit',
			'Plays a glow animation whenever you hit a note. Will not affect sustains and ghost taps, if turned off.',
			'pressAnimOnTap',
			BOOL
		));

		addOption(new Option(
			'Hide Tightest Judgement',
			'Hides the tightest judgement from the screen. Can make it easier to tell if you lost an FC, or if you just wanna focus better.',
			'hideTightestJudge',
			BOOL
		));

		addOption(new Option(
			'Noteskin:',
			'Choose a noteskin to show mid-game.',
			'noteSkin',
			STRING,
			['Funkin', 'Circle', 'Future']
		));

		addOption(new Option(
			'Note Splash Skin:',
			'Choose a note splash skin to show mid-game.',
			'noteSplashSkin',
			STRING,
			['None', 'Psych', 'Funkin']
		));

		addOption(new Option(
			'Time Bar Type:',
			'What kind of time bar should be displayed in-game?',
			'timeBarType',
			STRING,
			['Time Elapsed', 'Time Left', 'Song Name', 'Disabled']
		));

		var gameVisibility:Option = new Option(
			'Game Visibility:',
			'How transparent the HUD camera is.\nCan make it easier to read notes for people that have bad eyesight.',
			'gameVisibility',
			INT
		);
		gameVisibility.displayFormat = '%v%'; // cheeky workaround because percent doesn't wanna work properly
		gameVisibility.scrollSpeed = 2;
		gameVisibility.minValue = 0;
		gameVisibility.maxValue = 100;
		gameVisibility.changeValue = 5;
		addOption(gameVisibility);

		var noteSplashAlpha:Option = new Option(
			'Note Splash Visibility:',
			'How transparent the judgement sprite is.',
			'noteSplashAlpha',
			PERCENT
		);
		noteSplashAlpha.scrollSpeed = 2;
		noteSplashAlpha.minValue = 0;
		noteSplashAlpha.maxValue = 1;
		noteSplashAlpha.changeValue = 0.05;
		addOption(noteSplashAlpha);

		var judgementAlpha:Option = new Option(
			'Judgement Visibility:',
			'How transparent the note splashes are.',
			'judgementAlpha',
			PERCENT
		);
		judgementAlpha.scrollSpeed = 2;
		judgementAlpha.minValue = 0;
		judgementAlpha.maxValue = 1;
		judgementAlpha.changeValue = 0.05;
		addOption(judgementAlpha);

		var comboAlpha:Option = new Option(
			'Combo Visibility:',
			'How transparent the combo is.',
			'comboAlpha',
			PERCENT
		);
		comboAlpha.scrollSpeed = 2;
		comboAlpha.minValue = 0;
		comboAlpha.maxValue = 1;
		comboAlpha.changeValue = 0.05;
		addOption(comboAlpha);

		var healthBarAlpha:Option = new Option(
			'Health Bar Visibility:',
			'How transparent the health bar is.',
			'healthBarAlpha',
			PERCENT
		);
		healthBarAlpha.scrollSpeed = 2;
		healthBarAlpha.minValue = 0;
		healthBarAlpha.maxValue = 1;
		healthBarAlpha.changeValue = 0.05;
		addOption(healthBarAlpha);

		var scoreAlpha:Option = new Option(
			'Score Text Visibility:',
			'How transparent the score text is.',
			'scoreAlpha',
			PERCENT
		);
		scoreAlpha.scrollSpeed = 2;
		scoreAlpha.minValue = 0;
		scoreAlpha.maxValue = 1;
		scoreAlpha.changeValue = 0.05;
		addOption(scoreAlpha);

		addOption(new Option(
			'Camera Zooms',
			'Enables camera zooming in-game.',
			'cameraZooms',
			BOOL
		));
		
		addOption(new Option(
			'Transitions',
			'Whether transitions between states will appear or not.\nCan make going through menus faster if disabled.',
			'transitions',
			BOOL
		));

		var framerate:Option = new Option(
			'Framerate Cap:',
			'The max FPS the game can hit.',
			'framerate',
			INT
		);
		framerate.scrollSpeed = 2;
		framerate.minValue = 60;
		framerate.maxValue = 240;
		framerate.changeValue = 1;
		framerate.onChange = onChangeFramerate;
		addOption(framerate);

		var fpsCounter:Option = new Option(
			'FPS Counter',
			'Whether the FPS Counter is visible or not.',
			'fpsCounter',
			BOOL
		);
		fpsCounter.scrollSpeed = 2;
		fpsCounter.minValue = 60;
		fpsCounter.maxValue = 240;
		fpsCounter.changeValue = 1;
		fpsCounter.onChange = onChangeFPSCounter;
		addOption(fpsCounter);

		super();
	}

	function onChangeFramerate() {
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
	}

	function onChangeFPSCounter() {
		if (Main.fpsCounter == null) return;
		Main.fpsCounter.visible = Settings.data.fpsCounter;
	}
}
