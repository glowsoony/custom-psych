package funkin.options;

import flixel.group.FlxGroup;
import funkin.objects.AttachedText;
import funkin.objects.AttachedSprite;
import funkin.options.types.*;

class OptionsPage
{
	public var name:String = "";
	public var icon:String = "";
	public var options:Array<Dynamic> = [];

	// i tried @:structInit and it didn't work :<
	public function new(name:String, icon:String, options:Array<Dynamic>)
	{
		this.options = options ?? [];
		this.icon = icon;
		this.name = name;
	}

	public function toString()
		return this.name;
}

class NewOptionsMenu extends MusicState
{
	public var options:Array<OptionsPage> = [
		new OptionsPage("Controls", "keybinds", [
			new KeyOption("Left Note",
				"The actions attached to the left note.",
				"note_left"
			),
			new KeyOption("Down Note",
				"The actions attached to the down note.",
				"note_down"
			),
			new KeyOption("Up Note",
				"The actions attached to the up note.",
				"note_up"
			),
			new KeyOption("Right Note",
				"The actions attached to the right note.",
				"note_right"
			)
		]),
		new OptionsPage("Preferences", "gameplay", [
			// Example Choice Option
			new ChoiceOption("Scroll Direction", // Name
				"Which way the notes scroll to.", // Description
				"scrollDirection", // Setting (in Settings.hx)
				["Up", "Down"] // Choices
			),
			// Example Toggle
			new BoolOption("Centered Notes", // Name
				"Centers your notes and hides the opponent's.", // Description
				"centeredNotes" // Setting (in Settings.hx)
			),
		]),
		new OptionsPage("Visuals", "visuals", [
			new BoolOption("Flashing Lights",
				"Self explanatory. Can prevent seizures",
				"flashingLights"
			),
			new BoolOption('Judgement Counter',
				"Adds a counter to the left side of your screen\nthat counts how many judgements you\'ve hit.",
				"judgementCounter",
			),
		]),
	];

	// Array<Dynamic> cus I couldn't find a way to open other pages otherwise
	public var currentList:Array<Dynamic> = null;

	// used so you can open multiple option pages (JUST IN CASE RUDY WANTS ···)
	public var displayedPages:Array<OptionsPage> = [];

	public var curSelected(get, set):Int;
	public var pagesDeep:Int = -1;
	public var selected:Array<Int> = [0];

	public var optionNames:FlxTypedGroup<Alphabet>;
	public var optionValues:FlxTypedGroup<AttachedText>;

	public var pageIcons:FlxTypedGroup<flixel.FlxSprite>;
	public var pageText:FlxTypedGroup<Alphabet>;

	override function create():Void
	{
		super.create();

		var bg = null;
		add(bg = new FlxSprite(0, 0, Paths.image("menus/desatBG")));
		bg.color = 0xFFFFB560; // need a better colour??
		bg.screenCenter();

		add(optionNames = new FlxTypedGroup());
		add(optionValues = new FlxTypedGroup());
		regenList(options);

		add(pageIcons = new FlxTypedGroup());
		add(pageText = new FlxTypedGroup());
		for (i => page in options) {
			var icon = new FlxSprite(5, FlxG.height * 0.5 + 90 * (i - (options.length - 1) * 0.5), Paths.image("menus/option/" + page.icon));
			icon.y -= icon.height * 0.5;
			pageIcons.add(icon);

			var bet = new Alphabet(icon.x + icon.width - 30, icon.y + icon.height * 0.5, page.name);
			bet.updateScale(0.75, 0.75);
			bet.y -= bet.height * 0.5;
			bet.alpha = 0;
			pageText.add(bet);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (i => page in pageIcons) {
			var hover = FlxG.mouse.overlaps(page);
			var bet = pageText.members[i];
			bet.alpha = FlxMath.lerp(bet.alpha, hover ? 1 : 0, elapsed * 10);
			bet.x = FlxMath.lerp(bet.x, page.x + page.width - (hover ? 0 : 30), elapsed * 10);

			if (hover && FlxG.mouse.justReleased) {
				FlxG.sound.play(Paths.sound("confirmhalf"));
				displayedPages.splice(0, displayedPages.length);
				currentList = options;
				curSelected = i;
				pagesDeep = -1;
				openPage();
			}
		}

		if (optionNames.members.length > 1)
		{
			final downJustPressed:Bool = Controls.justPressed('ui_down');
			if (downJustPressed || Controls.justPressed('ui_up'))
				changeSelection(downJustPressed ? 1 : -1);
		}
		if (currentList != null)
		{
			final option = currentList[curSelected];
			final acceptJustPressed = Controls.justPressed("accept");
			if (!Std.isOfType(currentList[curSelected], OptionsPage))
			{
				// I couldn't find a better way :(
				if (option.hasMovement) // most options change like this
				{
					final leftJustPressed:Bool = Controls.justPressed('ui_left');
					if (leftJustPressed || Controls.justPressed('ui_right'))
					{
						option.change(leftJustPressed ? -1 : 1);
						FlxG.sound.play(Paths.sound("scroll"), 0.6);
					}
				}
				if (option.hasEnter && acceptJustPressed)
				{
					FlxG.sound.play(Paths.sound("confirmhalf"));
					option.enter();
				}
				updateHoveredItem();
			}
			else if (acceptJustPressed)
			{
				FlxG.sound.play(Paths.sound("confirmhalf"));
				openPage();
			}
		}
		if (Controls.justPressed("back"))
		{
			if (pagesDeep != -1)
				closePage();
			else
			{
				if (funkin.substates.PauseMenu.wentToOptions)
					MusicState.switchState(new PlayState());
				else
					MusicState.switchState(new MainMenuState());
			}
		}
	}

	function changeSelection(next:Int = 0, ?volume:Float = 0.4)
	{
		curSelected = FlxMath.wrap(curSelected + next, 0, optionNames.members.length - 1);

		if (next != 0)
			FlxG.sound.play(Paths.sound("scroll"), volume);

		final option = currentList[curSelected];
		if (!Std.isOfType(option, OptionsPage))
			option.onHover();

		for (i => opt in optionNames) {
			opt.alpha = i == curSelected ? 1.0 : 0.6;
			opt.targetY = i - curSelected;
			if (optionValues.members[i] != null)
				optionValues.members[i].alpha = opt.alpha;
		}
	}

	function openPage()
	{
		var hovered = currentList[curSelected];
		if (!displayedPages.contains(hovered))
			displayedPages.push(hovered);
		pagesDeep = FlxMath.wrap(pagesDeep + 1, 0, displayedPages.length - 1);
		selected.push(0);
		regenList(displayedPages[pagesDeep].options);
	}

	function closePage()
	{
		displayedPages.pop();
		selected.pop();
		pagesDeep = FlxMath.wrap(pagesDeep - 1, -1, displayedPages.length - 1);
		if (pagesDeep == -1)
			regenList(options);
		else
			regenList(displayedPages[pagesDeep].options);
	}

	function updateHoveredItem()
	{
		if (optionValues.members[curSelected] != null)
			optionValues.members[curSelected].text = currentList[curSelected].getText();
	}

	function regenList(list:Array<Dynamic>)
	{
		list ??= [];
		if (list.length == 0)
		{
			trace("Error reloading Options Menu list, The list is empty, maybe it's not valid?");
			return;
		}

		while (optionNames.members.length != 0)
			optionNames.members.pop().destroy();
		while (optionValues.members.length != 0)
			optionValues.members.pop().destroy();

		for (idx => opt in list)
		{
			final name:String = Std.string(Reflect.field(opt, "name") ?? opt); // ok.
			final style:AlphabetGlyphType = (opt is OptionsPage) ? BOLD : NORMAL; // this is going to look off ···
			final loveYourself:Alphabet = cast optionNames.add(new Alphabet(220, 260, name, style));
			loveYourself.isMenuItem = true;

			if (!Std.isOfType(opt, OptionsPage))
			{
				loveYourself.text = name + ":";
				var vX:Int = Math.floor(loveYourself.x + loveYourself.width) - 50;
				// different attachments per-value need to be set here, this is a placeholder
				final valueIndi:AttachedText = cast optionValues.add(new AttachedText(opt.getText(), vX, 0, NORMAL));
				// valueIndi.isMenuItem = loveYourself.isMenuItem;
				// valueIndi.targetY = loveYourself.targetY;
				// valueIndi.alpha = loveYourself.alpha;
				valueIndi.sprTracker = loveYourself;
			}
		}
		currentList = list;
		changeSelection();
	}

	function get_curSelected()
		return selected[selected.length - 1];
	function set_curSelected(next:Int)
		return selected[selected.length - 1] = next;
}
