package states.editors;

import backend.ui.*;
import objects.Bar;
import objects.Character;
import objects.CharIcon;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

class CharacterEditorState extends MusicState implements PsychUIEventHandler.PsychUIEvent {
	var camHUD:FlxCamera;
    override function create():Void {
        super.create();
        Conductor.stop();

		FlxG.autoPause = false;

        FlxG.sound.playMusic(Paths.music('artisticExpression'), 1, true);

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alpha = 0;

		add(ghost = new FlxSprite());
		ghost.visible = false;
		ghost.alpha = ghostAlpha;

		makeUI();
    }

	var healthBar:Bar;
	var icon:CharIcon;

	var anims(get, never):Array<CharacterAnim>;
	function get_anims():Array<CharacterAnim> return character.animationList;

	var animsTxt:FlxText;
	var curAnim = 0;

	var character:Character;
	var ghost:FlxSprite;
	var _char:String = Character.default_name;

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;
	function makeUI() {
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 280, ['Animations', 'Character']);
		UI_characterbox.scrollFactor.set();
		UI_characterbox.cameras = [camHUD];

		add(UI_characterbox);
		add(UI_box);

		add(animsTxt = new FlxText(10, Settings.data.fpsCounter ? 64 : 16, 400, ''));
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.borderSize = 1;
		animsTxt.cameras = [camHUD];

		add(healthBar = new Bar(30, FlxG.height - 75));
		healthBar.cameras = [camHUD];
		healthBar.scrollFactor.set();

		add(icon = new CharIcon('face'));
		icon.y = FlxG.height - 150;
		icon.cameras = [camHUD];

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();

		addCharacter();

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		reloadCharacterDropDown();
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI() {
		var tab_group = UI_box.getTab('Ghost').menu;

		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
			var anim:CharacterAnim = anims[curAnim];
			if (character.animation.curAnim == null) return;

			ghost.loadGraphic(character.graphic);
			ghost.frames.frames = character.frames.frames;
			ghost.animation.copyFrom(character.animation);
			ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
			ghost.animation.pause();
				
			if (ghost != null) {
				ghost.setPosition(character.x, character.y);
				ghost.antialiasing = character.antialiasing;
				ghost.flipX = character.flipX;
				ghost.alpha = ghostAlpha;

				ghost.scale.set(character.scale.x, character.scale.y);
				ghost.updateHitbox();

				ghost.offset.set(character.offset.x, character.offset.y);
				ghost.visible = true;
			}
			trace('created ghost image');
		});

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function() {
			var value:Int = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
		};

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float) {
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;

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
			addCharacter(true);
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", function() {
			
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;

		charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String) {
			if (intended == null || intended.length < 1) return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.get(characterPath);
			if (FileSystem.exists(path)) {
				_char = intended;
				addCharacter();
				reloadCharacterDropDown();
				updateText();
			} else {
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancel'));
			}
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
			var anim:CharacterAnim = anims[selectedAnimation];
			animationInputText.text = anim.name;
			animationNameInputText.text = anim.id;
			animationLoopCheckBox.checked = anim.looped;
			animationFramerate.value = anim.framerate;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if (indicesText.length > 0) {
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if (indicesStr.length > 0) {
					for (ind in indicesStr) {
						if (ind.contains('-')) {
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if (Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;
	
							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if (Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;
	
							for (index in indexStart...indexEnd + 1) indices.push(index);
						} else {
							var index:Int = Std.parseInt(ind);
							if (!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastOffsets:Array<Float> = [0, 0];
			for (anim in character.animationList) {
				if (animationInputText.text != anim.name) continue;

				lastOffsets = anim.offsets;
				if (character.animation.exists(animationInputText.text)) {
					character.animation.remove(animationInputText.text);
				}
				character.animationList.remove(anim);
			}

			var addedAnim:CharacterAnim = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.framerate = Math.round(animationFramerate.value);
			addedAnim.looped = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.name, addedAnim.id, addedAnim.framerate, addedAnim.looped, addedAnim.indices);
			character.animationList.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationList.indexOf(addedAnim)));
			character.playAnim(addedAnim.name, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function() {

		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation Name:'));
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
			character.sheets = imageInputText.text.split(',');
			reloadCharacterImage();
		});

		var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Colour", function() {
			var newColor:FlxColor = Util.dominantColor(icon);
			healthColorInputText.text = newColor.toHexString();
			updateHealthBar();
		});

		healthIconInputText = new PsychUIInputText(15, imageInputText.y + 36, 75, icon.name, 8);
		vocalsInputText = new PsychUIInputText(15, healthIconInputText.y + 35, 75, '', 8);
		singDurationStepper = new PsychUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);
		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = false;
		flipXCheckBox.onClick = function() character.flipX = flipXCheckBox.checked;

		antialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "Antialiasing", 80);
		antialiasingCheckBox.checked = true;
		antialiasingCheckBox.onClick = function() {
			character.antialiasing = antialiasingCheckBox.checked;
		};

		positionCameraXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, 0, -9000, 9000, 0);
		positionCameraYStepper = new PsychUINumericStepper(positionCameraXStepper.x + 70, positionCameraXStepper.y, 10, 0, -9000, 9000, 0);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, antialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
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
		tab_group.add(saveCharacterButton);
	}

	function updateHealthBar() {
		if (healthBar == null) return;
		healthBar.leftBar.color = healthBar.rightBar.color = Std.parseInt(healthColorInputText.text);

		icon.change(healthIconInputText.text);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		switch id {
			case PsychUIInputText.CHANGE_EVENT:
				if (sender == healthColorInputText || sender == healthIconInputText) {
					updateHealthBar();
				}

			case PsychUINumericStepper.CHANGE_EVENT:
				if (sender == scaleStepper) {
					character.scale.set(scaleStepper.value, scaleStepper.value);
					character.updateHitbox();
				}

				if (sender == singDurationStepper) {
					character.singDuration = singDurationStepper.value;
				}

			case _:
		}
	}

	function reloadAnimList() {
		if (anims.length > 0) character.playAnim(anims[0].name, true);
		curAnim = 0;

		updateText();
		if (animationDropDown != null) reloadAnimationDropDown();
	}

	function reloadAnimationDropDown() {
		var animList:Array<String> = [for (anim in anims) anim.name];
		if (animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

	function addCharacter(reload:Bool = false) {
		if (character != null) {
			remove(character);
			character.destroy();
		}

		add(character = new Character(0, 0, _char));
		character.autoIdle = false;
		reloadCharacterOptions();
		reloadAnimList();
	}

	inline function updateText() {
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		for (num => anim in character.animationList) {
			if (num > 0) intendText += '\n';

			if (num != curAnim) {
				intendText += anim.name + ": " + anim.offsets;
				continue;
			}

			var n:Int = intendText.length;
			intendText += anim.name + ": " + anim.offsets;
			animsTxt.addFormat(selectedFormat, n, intendText.length);
		}
		animsTxt.text = intendText;
	}

    override function update(elapsed:Float):Void {
        super.update(elapsed);

		if (PsychUIInputText.focusOn != null) {
			Controls.toggleVolumeKeys(false);
			return;
		}
		Controls.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if (FlxG.keys.pressed.SHIFT) {
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if (FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

        if (Controls.justPressed('back')) {
            MusicState.switchState(new MainMenuState());
        }

		if (FlxG.keys.pressed.A) FlxG.camera.scroll.x -= elapsed * 500;
		if (FlxG.keys.pressed.S) FlxG.camera.scroll.y += elapsed * 500;
		if (FlxG.keys.pressed.D) FlxG.camera.scroll.x += elapsed * 500;
		if (FlxG.keys.pressed.W) FlxG.camera.scroll.y -= elapsed * 500;

		var lastZoom:Float = FlxG.camera.zoom;
		if (FlxG.keys.justPressed.R) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
			if (FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		} else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
			if (FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		var changedAnim:Bool = false;
		if (anims.length > 1) {
	    	if (FlxG.keys.justPressed.UP && (changedAnim = true)) curAnim--;
			else if (FlxG.keys.justPressed.DOWN && (changedAnim = true)) curAnim++;

			if (changedAnim) {
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].name, true);
				updateText();
			}
		}

		var changedOffset:Bool = false;
		var moveKeysP:Array<Bool> = [FlxG.keys.justPressed.J, FlxG.keys.justPressed.L, FlxG.keys.justPressed.I, FlxG.keys.justPressed.K];
		if (moveKeysP.contains(true)) {
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		var anim:CharacterAnim = anims[curAnim];
		if (changedOffset && anim != null && anim.offsets != null) {
			anim.offsets = [character.offset.x, character.offset.y];

			character.setOffset(anim.name, [character.offset.x, character.offset.y]);
			updateText();
		}

		if (character.animation.curAnim != null) {
			if (FlxG.keys.justPressed.SPACE) 
				character.playAnim(character.animation.curAnim.name, true);
		}
    }

	inline function newAnim(name:String, id:String):CharacterAnim {
		return {
			offsets: [0, 0],
			looped: false,
			framerate: 24,
			name: name,
			indices: [],
			id: id
		};
	}

	function addAnimation(name:String, id:String, fps:Float, loop:Bool, ?indices:Array<Int>) {
		if (indices != null && indices.length > 0) character.animation.addByIndices(name, id, indices, "", fps, loop);
		else character.animation.addByPrefix(name, id, fps, loop);

		if (!character.animation.exists(name)) character.setOffset(name, [0.0, 0.0]);
	}

	function reloadCharacterDropDown() {
		var characterList:Array<String> = [];
		final directories:Array<String> = ['assets'];
		for (mod in Mods.getActive()) directories.push('mods/${mod.id}');

		for (i => path in directories) {
			if (!FileSystem.exists(path) || !FileSystem.exists('$path/characters')) continue;
			for (file in FileSystem.readDirectory('$path/characters')) {
				if (FileSystem.isDirectory(file)) continue;
				characterList.push(file.replace('.json', ''));
			}
		}

		if (characterList.length < 1) characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = _char;
	}

	function reloadCharacterImage() {
		var lastAnim:String = character.animation.curAnim.name;
		var oldAnims:Array<CharacterAnim> = character.animationList.copy();
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		character.frames = Paths.multiAtlas(character.sheets);

		for (anim in oldAnims) {
			var animName:String = anim.name;
			var animID:String = anim.id;
			var animFps:Int = anim.framerate;
			var animLoop:Bool = anim.looped;
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animName, animID, animFps, animLoop, animIndices);
		}

		if (oldAnims.length > 0) {
			if (lastAnim.length != 0) character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function reloadCharacterOptions() {
		if (UI_characterbox == null) return;

		imageInputText.text = character.sheets.join(',');
		healthIconInputText.text = character.icon;
		healthColorInputText.text = character.healthColor.toHexString();
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.scale.x;
		flipXCheckBox.checked = character.flipX;
		antialiasingCheckBox.checked = character.antialiasing;
		positionCameraXStepper.value = character.cameraOffset.x;
		positionCameraYStepper.value = character.cameraOffset.y;
		reloadAnimationDropDown();
		updateHealthBar();
	}

    override function destroy():Void {
        FlxG.sound.music.stop();
		Conductor.play();
		FlxG.autoPause = Settings.data.autoPause;
        super.destroy();
    }

	var _file:FileReference;
	function onSaveComplete(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		if (_file != null) return;

		var characterData:CharacterFile = {
			antialiasing: character.antialiasing,
			flipX: character.flipX,
			icon: character.icon,
			scale: character.scale.x,
			singDuration: character.singDuration,
			healthColor: character.healthColor,
			sheets: character.sheets.join(','),
			cameraOffset: [character.cameraOffset.x, character.cameraOffset.y],
			danceInterval: character.danceInterval,

			animations: character.animationList
		};

		// json5 pretty printing is fucked rn
		// so im just gonna print as normal json until it's fixed
		var dataStr:String = Json.stringify(characterData, '\t');

		if (dataStr.length > 0) {
			_file = new FileReference();
			_file.addEventListener(Event.SELECT, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(dataStr, '$_char.json');
		}
	}
}
