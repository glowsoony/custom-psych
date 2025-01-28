package states.editors;

import backend.ui.*;

class CharacterEditorState extends MusicState {

    override function create():Void {
        super.create();
        Conductor.stop();

		FlxG.autoPause = false;

        FlxG.sound.playMusic(Paths.music('artisticExpression'), 1, true);

		makeUI();
    }

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;
	function makeUI() {
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		UI_box.scrollFactor.set();

		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 280, ['Animations', 'Character']);
		UI_characterbox.scrollFactor.set();

		add(UI_characterbox);
		add(UI_box);
	
		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI() {
		var tab_group = UI_box.getTab('Ghost').menu;
		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
			
		});

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function() {

		};

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float) {
		
		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
	}

	var charDropDown:PsychUIDropDownMenu;
	function addSettingsUI() {
		var tab_group = UI_box.getTab('Settings').menu;

		var reloadCharacter:PsychUIButton = new PsychUIButton(140, 20, "Reload Char", function() {

		});

		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", function() {
			
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;

		charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String){
	
		});

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
	}

var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationsUI() {
		var tab_group = UI_characterbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Looped", 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {

		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {

		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function() {

		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation ID:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

var imageInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;
	var vocalsInputText:PsychUIInputText;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var antialiasingCheckBox:PsychUICheckBox;

	var healthColorInputText:PsychUIInputText;
	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;

	function addCharacterUI() {
		var tab_group = UI_characterbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(15, 30, 200, '', 8);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function() {

		});

		var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Colour", function() {

		});

		healthIconInputText = new PsychUIInputText(15, imageInputText.y + 36, 75, 'piss', 8);

		vocalsInputText = new PsychUIInputText(15, healthIconInputText.y + 35, 75, '', 8);

		singDurationStepper = new PsychUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = false;
		flipXCheckBox.onClick = function() {
		};

		antialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "Antialiasing", 80);
		antialiasingCheckBox.checked = true;
		antialiasingCheckBox.onClick = function() {
		
		};

		positionCameraXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, 0, -9000, 9000, 0);
		positionCameraYStepper = new PsychUINumericStepper(positionCameraXStepper.x + 70, positionCameraXStepper.y, 10, 0, -9000, 9000, 0);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, antialiasingCheckBox.y + 40, "Save Character", function() {

		});

		healthColorInputText = new PsychUIInputText(singDurationStepper.x, saveCharacterButton.y, 75, '0xFFFFFFFF', 8);
		healthColorInputText.maxLength = 10;

		tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Sheet(s):'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Icon Name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Duration:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y Offset:'));
		tab_group.add(new FlxText(healthColorInputText.x, healthColorInputText.y - 18, 100, 'Health Colour:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(antialiasingCheckBox);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorInputText);
/*		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);*/
		tab_group.add(saveCharacterButton);
	}

    override function update(elapsed:Float):Void {
        super.update(elapsed);

		if (PsychUIInputText.focusOn != null) {
			Controls.toggleVolumeKeys(false);
			return;
		}
		Controls.toggleVolumeKeys(true);

        if (Controls.justPressed('back')) {
            MusicState.switchState(new MainMenuState());
        }
    }

    override function destroy():Void {
        FlxG.sound.music.stop();
		Conductor.play();
		FlxG.autoPause = Settings.data.autoPause;
        super.destroy();
    }
}
