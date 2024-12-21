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

		var noteOffset:Option = new Option(
			'Note Offset:',
			'Shifts the notes by a certain amount, to make them more synced to the song.',
			'noteOffset',
			FLOAT
		);
		noteOffset.displayFormat = '%vms';
		noteOffset.scrollSpeed = 15;
		noteOffset.changeValue = 1;
		noteOffset.minValue = 0.0;
		noteOffset.maxValue = 300.0;
		addOption(noteOffset);

		var sickHitWindow:Option = new Option(
			'"Sick!" Hit Window:',
			'The timing for the "Sick!" judgement\'s hit window (in milliseconds).',
			'sickHitWindow',
			INT
		);
		sickHitWindow.displayFormat = '%vms';
		sickHitWindow.scrollSpeed = 15;
		sickHitWindow.minValue = 10;
		sickHitWindow.maxValue = 45;
		addOption(sickHitWindow);

		var goodHitWindow:Option = new Option(
			'"Good" Hit Window:',
			'The timing for the "Good" judgement\'s hit window (in milliseconds).',
			'goodHitWindow',
			INT
		);
		goodHitWindow.displayFormat = '%vms';
		goodHitWindow.scrollSpeed = 15;
		goodHitWindow.minValue = 11;
		goodHitWindow.maxValue = 90;
		addOption(goodHitWindow);

		var badHitWindow:Option = new Option(
			'"Bad" Hit Window:',
			'The timing for the "Bad" judgement\'s hit window (in milliseconds).',
			'sickHitWindow',
			INT
		);
		badHitWindow.displayFormat = '%vms';
		badHitWindow.scrollSpeed = 15;
		badHitWindow.minValue = 12;
		badHitWindow.maxValue = 135;
		addOption(badHitWindow);

		var shitHitWindow:Option = new Option(
			'"Shit" Hit Window:',
			'The timing for the "Shit" judgement\'s hit window (in milliseconds).',
			'goodHitWindow',
			INT
		);
		shitHitWindow.displayFormat = '%vms';
		shitHitWindow.scrollSpeed = 15;
		shitHitWindow.minValue = 13;
		shitHitWindow.maxValue = 180;
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

		var strumlineSize:Option = new Option(
			'Strumline Size:',
			'How big the strumlines will be. Can help on bigger monitors if the notes are too big.',
			'strumlineSize',
			PERCENT);
		strumlineSize.scrollSpeed = 1.6;
		strumlineSize.minValue = 0.0;
		strumlineSize.maxValue = 1;
		strumlineSize.changeValue = 0.1;
		strumlineSize.decimals = 1;
		strumlineSize.onChange = onChangeStrumlineSize;
		addOption(strumlineSize);

		addOption(new Option(
			'Reset Button',
			'Press "RESET" in-game to automatically die.',
			'canReset',
			BOOL
		));

		super();
	}

	function onChangeStrumlineSize() objects.Strumline.size = Settings.data.strumlineSize;
}