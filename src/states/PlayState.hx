package states;

import openfl.media.Sound;
import lime.ui.KeyCode;
import lime.app.Application;

import flixel.util.FlxSort;

import objects.*;
import objects.Note.NoteData;
import objects.Strumline.StrumNote;

import backend.Judgement;

import substates.PauseMenu;

class PlayState extends MusicState {
	public static var self:PlayState;

	// chart stuff
	public static var song:Chart;
	public static var songID:String;
	var songName:String;
	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;

	var notes:FlxTypedSpriteGroup<Note>;
	var unspawnedNotes:Array<Note> = [];

	// gameplay logic stuff
	var scrollType:String;
	var scrollSpeed(default, set):Float = 1;
	function set_scrollSpeed(value:Float):Float {
		var ratio:Float = value / scrollSpeed;
		if (ratio != 1) {
			for (note in unspawnedNotes) {
				note.resizeByRatio(ratio);
			}
		}

		return scrollSpeed = value;
	}

	public var botplay(default, set):Bool = false;
	function set_botplay(value:Bool):Bool {
		if (playerStrums != null) playerStrums.player = value;
		return botplay = value;
	}

	var downscroll:Bool;

	var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		return health = FlxMath.bound(value, 0, 100);
	}

	var playbackRate(default, set):Float = 1;
	function set_playbackRate(value:Float):Float {
		#if FLX_PITCH
		Conductor.rate = value;

		var ratio:Float = playbackRate / value; //funny word huh
		if (ratio != 1) {
			for (note in unspawnedNotes) note.resizeByRatio(ratio);
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	var combo:Int = 0;
	var comboBreaks:Int = 0;
	var score:Int = 0;
	var accuracy:Float = 0.0;

	var totalNotesPlayed:Float = 0.0;
	var totalNotesHit:Int = 0;

	public var paused:Bool = false;

	// objects
	var bf:Character;
	var dad:Character;
	var gf:Character;

	var opponentStrums:Strumline;
	var playerStrums:Strumline;

	var hudGroup:FlxSpriteGroup;

	var scoreTxt:FlxText;

	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;

	var healthBar:Bar;
	var iconP1:CharIcon;
	var iconP2:CharIcon;

	// cameras
	var camHUD:FlxCamera;
	var camOther:FlxCamera;

	// whatever variables i also need lmao
	final iconSpacing:Float = 20;

	var keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	override function create() {
		super.create();
		Paths.clearStoredMemory();
		Language.reloadPhrases();

		self = this;

		Conductor.stop();

		// precache the pause menu music
		// to prevent the pause menu freezing on first pause
		PauseMenu.musicPath = Settings.data.pauseMusic;
		Paths.music(PauseMenu.musicPath); 

		Settings.data.scrollDirection = 'Down';

		// set up gameplay settings
		scrollType = Settings.data.gameplaySettings['scrollType'];
		botplay = Settings.data.gameplaySettings['botplay'];
		playbackRate = Settings.data.gameplaySettings['playbackRate'];
		downscroll = Settings.data.scrollDirection == 'Down';

		// set up cameras
		FlxG.cameras.reset();

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.stageBrightness * 0.01);

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		// characters
		add(dad = new Character(100, 225, '', false));
		add(bf = new Character(750, 225));

		// set up strumlines and the note group
		final strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;
		add(playerStrums = new Strumline(750, strumlineYPos, !botplay));
		add(opponentStrums = new Strumline(100, strumlineYPos));

		playerStrums.cameras = [camHUD];
		opponentStrums.cameras = [camHUD];

		if (Settings.data.centeredNotes) {
			playerStrums.screenCenter(X);
			opponentStrums.alpha = 0;
		}

		if (!Settings.data.opponentNotes) opponentStrums.alpha = 0;

		add(notes = new FlxTypedSpriteGroup<Note>());
		notes.cameras = [camHUD];

		// set up hud elements
		add(hudGroup = new FlxSpriteGroup());
		hudGroup.cameras = [camHUD];

		hudGroup.add(healthBar = new Bar(0, downscroll ? 55 : 640, 'healthBar', function() return health, 0, 100));
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;

		hudGroup.add(iconP1 = new CharIcon('face', true));
		iconP1.y = healthBar.y - healthBar.height - (iconP1.height * 0.5);

		hudGroup.add(iconP2 = new CharIcon('face'));
		iconP2.y = healthBar.y - healthBar.height - (iconP2.height * 0.5);

		updateIconPositions();

		scoreTxt = new FlxText(0, downscroll ? 21 : FlxG.height - 39, FlxG.width, 'Score: 0 | Combo Breaks: 0 | Accuracy: ?', 16);
		scoreTxt.font = Paths.font('vcr.ttf');
		scoreTxt.alignment = CENTER;
		scoreTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		scoreTxt.borderColor = FlxColor.BLACK;
		scoreTxt.borderSize = 1.25;
		hudGroup.add(scoreTxt);
		scoreTxt.screenCenter(X);

		hudGroup.add(judgeSpr = new JudgementSpr(Settings.data.judgePosition[0], Settings.data.judgePosition[1]));
		hudGroup.add(comboNumbers = new ComboNums(Settings.data.comboPosition[0], Settings.data.comboPosition[1]));

		// set up any other stuff we might need
		Application.current.window.onKeyDown.add(keyPressed);
		Application.current.window.onKeyUp.add(keyReleased);

		loadSong(songID);
		Conductor.play();

		// setting this after loading all the notes
		// otherwise sustain scaling will get fucked and look weird
		// idk why either :Bert:
		scrollSpeed = switch (scrollType) {
			case 'Constant': Settings.data.gameplaySettings['scrollSpeed'];
			case 'Multiplicative': song.speed * Settings.data.gameplaySettings['scrollSpeed'];
			default: song.speed;
		}

		FlxG.mouse.visible = false;
	}

	function loadSong(id:String):Void {
		Conductor.setBPMChanges(song);
		Conductor.bpm = song.bpm;
		songName = song.song;

		// load inst
		try {
			Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
			Conductor.inst.onComplete = endSong;
		} catch (e:Dynamic) {
			Sys.println('Instrumental failed to load: $e');
		}

		// load vocals
		try {
			if (song.needsVoices) {
				var mainFile:Sound = Paths.audio('songs/$songID/Voices-Player', null, false);
				var opponentFile:Sound = Paths.audio('songs/$songID/Voices-Opponent', null, false);

				if (mainFile == null) mainFile = Paths.audio('songs/$songID/Voices');

				Conductor.mainVocals = FlxG.sound.load(mainFile);
				if (opponentFile != null) Conductor.opponentVocals = FlxG.sound.load(opponentFile);
			}
		} catch (e:Dynamic) {
			Sys.println('Vocals failed to load: $e');
		}

		loadNotes(songID);
	}

	function loadNotes(id:String) {
		var parsedNotes:Array<NoteData> = Song.parse(song);

		notes.clear();

		var oldNote:Note = null;
		for (i => note in parsedNotes) {
			var daBPM:Float = Conductor.getBPMChangeFromMS(note.time).bpm;

			if (i != 0) {
				// CLEAR ANY POSSIBLE GHOST NOTES
				for (evilNote in unspawnedNotes) {
					var matches:Bool = (note.lane == evilNote.lane && note.player == evilNote.player);
					if (matches && Math.abs(note.time - evilNote.time) < 2.0) {
						evilNote.destroy();
						unspawnedNotes.remove(evilNote);
					}
				}
			}

			var swagNote:Note = new Note(note, oldNote);
			unspawnedNotes.push(swagNote);

			var curStepCrochet:Float = (60 / daBPM) * 1000 * 0.25;
			final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
			if (roundSus > 0) {
				for (susNote in 0...roundSus) {
					oldNote = unspawnedNotes[unspawnedNotes.length - 1];

					var sustainNote:Note = new Note({
						time: note.time + (curStepCrochet * susNote),
						lane: note.lane,
						length: note.length,
						type: note.type,
						player: note.player,
						speed: note.speed
					}, oldNote, true);
					sustainNote.parent = swagNote;
					sustainNote.correctionOffset.y = Settings.data.scrollDirection == 'Down' ? 0 : swagNote.height * 0.5;
					unspawnedNotes.push(sustainNote);
					swagNote.pieces.push(sustainNote);

					if (oldNote.isSustain) {
						oldNote.scale.y *= 44 / oldNote.frameHeight;
						oldNote.scale.y /= playbackRate;
						oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrotchet);
					}
				}
			}

			oldNote = swagNote;
		}

		unspawnedNotes.sort((a, b) -> Std.int(a.time - b.time));
		oldNote = null;
	}

	var canPause:Bool = true;
	override function update(elapsed:Float):Void {
		// note spawning
		while (noteSpawnIndex < unspawnedNotes.length) {
			final noteToSpawn:Note = unspawnedNotes[noteSpawnIndex];
			if (noteToSpawn.hitTime > noteSpawnDelay) break;

			notes.add(noteToSpawn);
			noteToSpawn.spawned = true;
			noteSpawnIndex++;
		}

		for (note in notes.members) {
			if (note == null || !note.alive) continue;

			final strum:StrumNote = (note.player ? playerStrums : opponentStrums).members[note.lane];
			note.followStrum(strum, scrollSpeed);

			if (note.player) {
				if (botplay) checkNoteHitWithAI(strum, note);
				else if (note.isSustain) sustainInputs(strum, note);
			} else checkNoteHitWithAI(strum, note);

			if (note.player && !note.missed && !note.isSustain && note.tooLate) {
				note.missed = true;
				noteMiss(note);
			}

			if (note.time < Conductor.time - 300) {
				notes.remove(note);
				note.destroy();
			}
		}

		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * playbackRate));

		updateIconScales(elapsed);
		updateIconPositions();

		if (Controls.justPressed('pause') && canPause) openPauseMenu();

		super.update(elapsed);
	}

	public dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	public dynamic function updateIconScales(elapsed:Float):Void {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	public function endSong():Void {
		Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'));
		Conductor.vocals.destroy();
		Conductor.play();

		MusicState.switchState(new FreeplayState());
	}

	// ai note hitting
	dynamic function checkNoteHitWithAI(strum:StrumNote, note:Note):Void {
		if (!note.canHit || note.time >= Conductor.time) return;

		final func = note.player ? noteHit : opponentNoteHit;

		// sustain input
		if (note.isSustain) {
			note.clipToStrum(strum);
			if (note.wasHit) return;

			note.wasHit = true;
			strum.playAnim('notePressed');
			func(note);
			return;
		}

		// normal notes
		strum.playAnim('notePressed');
		note.wasHit = true;
		func(note);
		note.destroy();
		notes.remove(note);
	}

	dynamic function opponentNoteHit(note:Note) {
		if (song.needsVoices && Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;

		dad.playAnim('sing${Note.directions[note.lane].toUpperCase()}');
	}

	// note hitting specific to the player
	dynamic function sustainInputs(strum:StrumNote, note:Note) {
		var parent:Note = note.parent;

		if (!parent.canHit || parent.missed) return;

		var heldKey:Bool = keysHeld[parent.lane];
		var tooLate:Bool = (parent.wasHit ? note.time < Conductor.time : parent.tooLate);
		var isTail:Bool = note.animation.curAnim.name == 'holdend';

		if (!heldKey) {
			if (tooLate && !note.wasHit) {
				// ignore tails completely
				if (isTail) {
					note.destroy();
					notes.remove(note);
					return;
				}

				noteMiss(note);
				parent.missed = true;
				for (piece in parent.pieces) {
					if (piece == null || !piece.exists || !piece.alive) continue;
					piece.multAlpha = 0.2;
				}
			}

			return;
		}

		note.clipToStrum(strum);

		if (note.time <= Conductor.time && !note.wasHit) note.wasHit = true;
		else return;
		
		strum.playAnim('notePressed');
		bf.playAnim('sing${Note.directions[parent.lane].toUpperCase()}');
	}

	dynamic function noteHit(note:Note) {
		playerStrums.members[note.lane].playAnim('notePressed');
		note.wasHit = true;

		if (song.needsVoices) Conductor.mainVocals.volume = 1;

		totalNotesHit++;
		
		// pbot1 scoring system
		// cuz judgement based is super boring :sob:
		score += Math.floor(500 - Math.abs(note.hitTime));
		for (id => judge in Judgement.list) {
			if (Math.abs(note.hitTime) >= judge.timing) continue;

			totalNotesPlayed += judge.accuracy;
			health += judge.health;
			judgeSpr.display(judge.name);

			break;
		}

		combo++;
		comboNumbers.display(combo);

		bf.playAnim('sing${Note.directions[note.lane].toUpperCase()}');

		updateAccuracy();
		updateScoreTxt();

		note.destroy();
		notes.remove(note);
	}

	dynamic function noteMiss(note:Note) {
		comboBreaks++;
		combo = 0;
		score -= 20;
		health -= 6;

		if (song.needsVoices) Conductor.mainVocals.volume = 0;
		bf.playAnim('miss${Note.directions[note.lane].toUpperCase()}');

		updateAccuracy();
		updateScoreTxt();
	}

	override function beatHit(beat:Int) {
		super.beatHit(beat);

		iconP1.scale.set(1.2, 1.2);
		iconP1.updateHitbox();

		iconP2.scale.set(1.2, 1.2);
		iconP2.updateHitbox();

		if (beat % 2 == 0) {
			bf.dance();
			dad.dance();
		}
	}

	override function measureHit(measure:Int) {
		super.measureHit(measure);
		camHUD.zoom += 0.015;
	}

	function openPauseMenu() {
		persistentUpdate = false;
		Conductor.pause();
		paused = true;
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);

		var menu:PauseMenu = new PauseMenu(songName, Difficulty.current, 0);
		openSubstate(menu);
		menu.camera = camOther;
	}

	// in case someone wants to make their own accuracy calc
	dynamic function updateAccuracy() {
		accuracy = totalNotesPlayed / (totalNotesHit + comboBreaks);
	}

	dynamic function updateScoreTxt() {
		scoreTxt.text = 'Score: $score | Combo Breaks: $comboBreaks | Accuracy: ${Util.truncateFloat(accuracy, 2)}%';
	}

	var keysHeld:Array<Bool> = [for (_ in 0...Strumline.keyCount) false];
	inline function keyPressed(key:KeyCode, _):Void {
		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1 || keysHeld[dir] || botplay || paused) return;

		var strum:StrumNote = playerStrums.members[dir];
		final sortedNotes:Array<Note> = notes.members.filter(function(note:Note):Bool {
			// make the long ass return more readable
			if (note == null) return false;
			return note.hittable && note.lane == dir && note.player && !note.isSustain;
		});

		if (sortedNotes.length == 0) {
			strum.playAnim('pressed');
		} else {
			sortedNotes.sort((a, b) -> Std.int(a.time - b.time));
			var note:Note = sortedNotes[0];
			noteHit(note);
			note = null;
		}

		keysHeld[dir] = true;
	}

	inline function keyReleased(key:KeyCode, _):Void {
		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1 || botplay) return;
		keysHeld[dir] = false;

		playerStrums.members[dir].playAnim('default');
	}

	override function destroy() {
		closeSubstate();
		resetSubstate();
		FlxG.camera.setFilters([]);

		Application.current.window.onKeyDown.remove(keyPressed);
		Application.current.window.onKeyUp.remove(keyReleased);

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		self = null;
		super.destroy();
	}
}