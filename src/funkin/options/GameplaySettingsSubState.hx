package funkin.options;

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
			'Pausing:',
			'Unlimited: Can pause as much as you like, similar to Base FNF and StepMania.\nLimited: Can only pause a certain amount of times, similar to Osu! and Quaver.\nDisabled: Prevents you from pausing at all, like Etterna.',
			'pauseType',
			STRING,
			['Unlimited', 'Limited', 'Disabled']
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
			'Whether you get punished or not for pressing a key that has no hittable notes.',
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
			'Shifts the notes by a certain amount, to make them more synced to the song.\nPositive = earlier, negative = later',
			'noteOffset',
			FLOAT
		);
		noteOffset.displayFormat = '%vms';
		noteOffset.scrollSpeed = 15;
		noteOffset.changeValue = 1;
		noteOffset.minValue = -500.0;
		noteOffset.maxValue = 500.0;
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
			'badHitWindow',
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
			'shitHitWindow',
			INT
		);
		shitHitWindow.displayFormat = '%vms';
		shitHitWindow.scrollSpeed = 15;
		shitHitWindow.minValue = 13;
		shitHitWindow.maxValue = 180;
		addOption(shitHitWindow);

		var strumlineSize:Option = new Option(
			'Strumline Size:',
			'How big the strumlines will be. Can help on bigger monitors if the notes are too big.',
			'strumlineSize',
			PERCENT);
		strumlineSize.scrollSpeed = 1.6;
		strumlineSize.minValue = 0.0;
		strumlineSize.maxValue = 1;
		strumlineSize.changeValue = 0.05;
		strumlineSize.decimals = 2;
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

	function onChangeStrumlineSize() funkin.objects.Strumline.size = Settings.data.strumlineSize;
}