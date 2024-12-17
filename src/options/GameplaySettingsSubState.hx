package options;

class GameplaySettingsSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('gameplay_menu', 'Gameplay Settings');
		rpcTitle = 'Gameplay Settings Menu';

		addOption(new Option(
			'Scroll Direction:',
			'Which way the notes will scroll.',
			'scrollDirection',
			STRING,
			['Up', 'Down']
		));

		addOption(new Option(
			'Opponent Notes',
			'Whether to have the opponent\'s notes on screen or not.\nIs ignored if "Centered Notes" is enabled.',
			'opponentNotes',
			BOOL
		));

		addOption(new Option(
			'Centered Notes',
			'Centers the player\'s notes to the middle of the screen.',
			'centeredNotes',
			BOOL
		));

		addOption(new Option(
			'Ghost Tapping',
			'write the description for this later because im dum lol lmao',
			'ghostTapping',
			BOOL
		));

		addOption(new Option(
			'Mechanics',
			'Enables mechanics for specific songs.\n(gremlin/signs from expurgation, saws from termination, etc)',
			'mechanics',
			BOOL
		));

		var sickHitWindow:Option = new Option(
			'"Sick!" Hit Window:',
			'The timing for the "Sick!" judgement\'s hit window (in milliseconds).',
			'sickHitWindow',
			FLOAT
		);
		sickHitWindow.displayFormat = '%vms';
		sickHitWindow.changeValue = 0.1;
		sickHitWindow.scrollSpeed = 15;
		sickHitWindow.minValue = 10.0;
		sickHitWindow.maxValue = 45.0;
		addOption(sickHitWindow);

		var goodHitWindow:Option = new Option(
			'"Good" Hit Window:',
			'The timing for the "Good" judgement\'s hit window (in milliseconds).',
			'goodHitWindow',
			FLOAT
		);
		goodHitWindow.displayFormat = '%vms';
		goodHitWindow.scrollSpeed = 15;
		goodHitWindow.changeValue = 0.1;
		goodHitWindow.minValue = 11.0;
		goodHitWindow.maxValue = 90.0;
		addOption(goodHitWindow);

		var badHitWindow:Option = new Option(
			'"Bad" Hit Window:',
			'The timing for the "Bad" judgement\'s hit window (in milliseconds).',
			'sickHitWindow',
			FLOAT
		);
		badHitWindow.displayFormat = '%vms';
		badHitWindow.changeValue = 0.1;
		badHitWindow.scrollSpeed = 15;
		badHitWindow.minValue = 12.0;
		badHitWindow.maxValue = 135.0;
		addOption(badHitWindow);

		var shitHitWindow:Option = new Option(
			'"Shit" Hit Window:',
			'The timing for the "Shit" judgement\'s hit window (in milliseconds).',
			'goodHitWindow',
			FLOAT
		);
		shitHitWindow.displayFormat = '%vms';
		shitHitWindow.changeValue = 0.1;
		shitHitWindow.scrollSpeed = 15;
		shitHitWindow.minValue = 13.0;
		shitHitWindow.maxValue = 180.0;
		addOption(shitHitWindow);

		var hitsoundVolume:Option = new Option(
			'Hitsound Volume:',
			'write the description for this later because im dum lol lmao',
			'hitsoundVolume',
			PERCENT);
		hitsoundVolume.scrollSpeed = 1.6;
		hitsoundVolume.minValue = 0.0;
		hitsoundVolume.maxValue = 1;
		hitsoundVolume.changeValue = 0.1;
		hitsoundVolume.decimals = 1;
		addOption(hitsoundVolume);

		addOption(new Option(
			'Reset Button',
			'Press "RESET" in-game to automatically die.',
			'canReset',
			BOOL
		));

		super();
	}
}