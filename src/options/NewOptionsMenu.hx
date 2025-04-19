package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import states.MusicState;
import objects.Alphabet;
import objects.AttachedText;
import objects.AttachedSprite;
import options.types.*;

class OptionsPage
{
	public var name:String = "";
	public var options:Array<Dynamic> = [];

	// i tried @:structInit and it didn't work :<
	public function new(name:String, options:Array<Dynamic>)
	{
		this.options = options ?? [];
		this.name = name;
	}

	public function toString()
		return this.name;
}

class NewOptionsMenu extends MusicState
{
	public var options:Array<OptionsPage> = [
		new OptionsPage("Preferences", [
			// Example Choice Option
			new ChoiceOption("Scroll Direction", "Which way the notes scroll to.", // Description
				"scrollDirection", // Setting (in Settings.hx)
				["Up", "Down"] // Choices
			),
			// Example Toggle
			new BoolOption("Centered Notes", // Name
				"Centers your notes and hides the opponent's.", // Description
				"centeredNotes" // Setting (in Settings.hx)
			),
		]),
	];

	// Array<Dynamic> cus I couldn't find a way to open other pages otherwise
	public var currentList:Array<Dynamic> = null;

	// used so you can open multiple option pages (JUST IN CASE RUDY WANTS ···)
	public var displayedPages:Array<OptionsPage> = [];

	public var curSelected:Int = 0;
	public var pagesDeep:Int = -1;

	public var optionNames:FlxTypedGroup<flixel.FlxSprite>;
	public var optionValues:FlxTypedGroup<flixel.FlxSprite>;

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
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
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
				if (!Std.isOfType(option, BoolOption)) // most options change like this
				{
					final leftJustPressed:Bool = Controls.justPressed('ui_left');
					if (leftJustPressed || Controls.justPressed('ui_right'))
					{
						option.change(leftJustPressed ? 1 : -1);
						FlxG.sound.play(Paths.sound("scroll"), 0.6);
					}
				}
				else if (option is BoolOption && acceptJustPressed)
				{
					FlxG.sound.play(Paths.sound("confirmhalf"));
					cast(option, BoolOption).change(!option.value); // haxe.
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
				if (substates.PauseMenu.wentToOptions)
					MusicState.switchState(new states.PlayState());
				else
					MusicState.switchState(new states.MainMenuState());
			}
		}
	}

	function changeSelection(next:Int = 0, ?volume:Float = 0.4)
	{
		if (optionNames.members[curSelected] != null)
			optionNames.members[curSelected].alpha = 0.6;
		curSelected = FlxMath.wrap(curSelected + next, 0, optionNames.members.length - 1);
		optionNames.members[curSelected].alpha = 1.0;
		if (next != 0)
			FlxG.sound.play(Paths.sound("scroll"), volume);
		final option = currentList[curSelected];
		if (!Std.isOfType(option, OptionsPage))
			option.onHover();
	}

	function openPage()
	{
		var hovered = currentList[curSelected];
		if (!displayedPages.contains(hovered))
			displayedPages.push(hovered);
		pagesDeep = FlxMath.wrap(pagesDeep + 1, 0, displayedPages.length - 1);
		regenList(displayedPages[pagesDeep].options);
	}

	function closePage()
	{
		pagesDeep = FlxMath.wrap(pagesDeep - 1, -1, displayedPages.length - 1);
		if (pagesDeep == -1)
			regenList(options);
		else
			regenList(displayedPages[pagesDeep].options);
	}

	function updateHoveredItem()
	{
		// i hate this
		if (optionValues.members[curSelected] != null)
		{
			final v:String = Std.string(currentList[curSelected].value); // shortening
			cast(optionValues.members[curSelected], AttachedText).text = v;
		}
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
		for (idx => opt in list)
		{
			final name:String = Std.string(Reflect.field(opt, "name") ?? opt); // ok.
			final style:AlphabetGlyphType = (opt is OptionsPage) ? BOLD : NORMAL; // this is going to look off ···
			final loveYourself:Alphabet = cast optionNames.add(new Alphabet(220, 260, name, style));
			loveYourself.isMenuItem = true;
			loveYourself.targetY = idx;
			loveYourself.alpha = 0.6;

			if (!Std.isOfType(opt, OptionsPage))
			{
				loveYourself.text = name + ":";
				var vX:Int = Math.floor(loveYourself.x + loveYourself.width) - 50;
				// different attachments per-value need to be set here, this is a placeholder
				final valueIndi:AttachedText = cast optionValues.add(new AttachedText(Std.string(opt.value), vX, 0, NORMAL));
				// valueIndi.isMenuItem = loveYourself.isMenuItem;
				// valueIndi.targetY = loveYourself.targetY;
				// valueIndi.alpha = loveYourself.alpha;
				valueIndi.sprTracker = loveYourself;
			}
		}
		currentList = list;
		curSelected = 0;
		changeSelection();
	}
}
