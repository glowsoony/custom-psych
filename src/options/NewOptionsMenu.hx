package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;

import states.MusicState;
import objects.Alphabet;
import options.types.*;

class OptionsPage {
    public var name:String = "";
    public var options:Array<Dynamic> = [];

    // i tried @:structInit and it didn't work :<
    public function new(name:String, options:Array<Dynamic>) {
        this.options = options ?? [];
        this.name = name;
    }

    public function toString() return this.name;
}

class NewOptionsMenu extends MusicState {
    public var options:Array<OptionsPage> = [
        new OptionsPage("Preferences", [
            new BaseOption(
                "Centered Notes", // Name
                "Whether to have the opponent\'s notes on screen or not.\nIs ignored if \"Centered Notes\" is enabled", // Description
                "centeredNotes",
            ),
            new OptionsPage("Sub    ", [
                new BaseOption("Friday Night Funkin'", "fnf"),
            ]),
        ]),
    ];

    public var currentList:Array<Dynamic> = null;

    // used so you can open multiple option pages (JUST IN CASE RUDY WANTS ···)
    public var displayedPages:Array<OptionsPage> = [];

    public var curSelected:Int = 0;
    public var pagesDeep:Int = -1;

    var letters:FlxTypedGroup<Alphabet>;

    override function create():Void {
        super.create();

        var bg = null;
        add(bg = new FlxSprite(0, 0, Paths.image("menus/desatBG")));
        bg.color = 0xFFFFB560;
        bg.screenCenter();

        add(letters = new FlxTypedGroup<Alphabet>());
        regenList(options);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        if (letters.members.length > 1) {
            final downJustPressed:Bool = Controls.justPressed('ui_down');
            if (downJustPressed || Controls.justPressed('ui_up'))
                changeSelection(downJustPressed ? 1 : -1);
        }
        if (Controls.justPressed("accept")) {
            FlxG.sound.play(Paths.sound("confirmhalf"));
            if (currentList != null && currentList[curSelected] is OptionsPage)
                openPage();
        }
        if (Controls.justPressed("back")) {
            if (pagesDeep != -1)
                closePage();
            else
                MusicState.switchState(new states.MainMenuState());
        }
    }

    function changeSelection(next:Int = 0, ?volume:Float = 0.4) {
        if (letters.members[curSelected] != null) letters.members[curSelected].alpha = 0.6;
        curSelected = FlxMath.wrap(curSelected + next, 0, letters.members.length - 1);
        letters.members[curSelected].alpha = 1.0;
        if (next != 0) FlxG.sound.play(Paths.sound("scroll"), volume);
    }

    function openPage() {
        var hovered = currentList[curSelected];
        if (!displayedPages.contains(hovered))
            displayedPages.push(hovered);
        pagesDeep = FlxMath.wrap(pagesDeep + 1, 0, displayedPages.length - 1);
        regenList(displayedPages[pagesDeep].options);
    }

    function closePage() {
        pagesDeep = FlxMath.wrap(pagesDeep - 1, -1, displayedPages.length - 1);
        if (pagesDeep == -1)
            regenList(options);
        else
            regenList(displayedPages[pagesDeep].options);
    }

    function regenList(list:Array<Dynamic>) {
        list ??= [];
        if (list.length == 0) {
            trace("Error reloading Options Menu list, The list is empty, maybe it's not valid?");
            return;
        }
        while (letters.members.length != 0)
            letters.members.pop().destroy();
        for (idx => opt in list) {
            final name:String = Std.string(Reflect.field(opt, "name") ?? opt); // ok.
            final style:AlphabetGlyphType = (opt is OptionsPage) ? BOLD : NORMAL; // this is going to look off ···
            final loveYourself:Alphabet = letters.add(new Alphabet(220, 260, name, style));
            loveYourself.isMenuItem = true;
            loveYourself.targetY = idx;
            loveYourself.alpha = 0.6;
        }
        currentList = list;
        curSelected = 0;
        changeSelection();
    }
}
