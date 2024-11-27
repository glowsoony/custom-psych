package states;

import openfl.media.Sound;
import lime.ui.KeyCode;
import lime.app.Application;

import objects.*;
import objects.Note;
import objects.Strumline.StrumNote;

import backend.Judgement;

class PlayState extends MusicState {
	public static var song:Chart;

	var scrollSpeed(default, set):Float = 1;
	var scrollType:String;

	function set_scrollSpeed(value:Float):Float {
		var ratio:Float = value / scrollSpeed; //funny word huh
		if (ratio != 1) {
			for (note in unspawnedNotes) {
				note.resizeByRatio(ratio);
			}
		}

		return scrollSpeed = value;
	}

	public var opponentStrums:Strumline;
	public var playerStrums:Strumline;

	public var botplay(default, set):Bool = false;
	function set_botplay(value:Bool):Bool {
		if (playerStrums != null) playerStrums.player = value;
		return botplay = value;
	}

	var songName:String;
	public static var songID:String;
	public var paused:Bool = false;
	public static var self:PlayState;

	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;

	var comboBreaks:Int = 0;
	var score:Int = 0;
	var accuracy:Float = 0.0;

	var totalNotesPlayed:Float = 0.0;
	var totalNotesHit:Int = 0;

	var combo:Int = 0;
	
	var notes:FlxTypedSpriteGroup<Note>;
	var unspawnedNotes:Array<Note> = [];

	var scoreTxt:FlxText;

	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;

	var keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	var camHUD:FlxCamera;
	var hudGroup:FlxSpriteGroup;

	override function create() {
		Paths.clearStoredMemory();
		Language.reloadPhrases();

		super.create();
		self = this;

		scrollType = Settings.data.gameplaySettings['scrollType'];
		botplay = Settings.data.gameplaySettings['botplay'];

		FlxG.cameras.reset();
/*		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.stageBrightness * 0.01);*/

		final downscroll:Bool = Settings.data.scrollDirection == 'Down';
		final strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;

		add(playerStrums = new Strumline(750, strumlineYPos, !botplay));
		add(opponentStrums = new Strumline(100, strumlineYPos));

		if (Settings.data.centeredNotes) {
			playerStrums.screenCenter(X);
			opponentStrums.alpha = 0;
		}

		if (!Settings.data.opponentNotes) opponentStrums.alpha = 0;

		add(notes = new FlxTypedSpriteGroup<Note>());

		add(hudGroup = new FlxSpriteGroup());
		//hudGroup.cameras = [camHUD];

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

		Application.current.window.onKeyDown.add(keyPressed);
		Application.current.window.onKeyUp.add(keyReleased);

		loadSong(songID);
		Conductor.play();

		scrollSpeed = switch (scrollType) {
			case 'Constant': Settings.data.gameplaySettings['scrollSpeed'];
			case 'Multiplicative': song.speed * Settings.data.gameplaySettings['scrollSpeed'];
			default: song.speed;
		}
	}

	function loadSong(id:String):Void {
		if (Conductor.inst != null) Conductor.inst.stop();

		Conductor.setBPMChanges(song);
		Conductor.bpm = song.bpm;
		songName = song.song;

		// load inst
		try {
			Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
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
			if (roundSus > 1) {
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
					swagNote.tail.push(sustainNote);

					if (oldNote.isSustain) {
						oldNote.scale.y *= 44 / oldNote.frameHeight;
						//oldNote.scale.y /= playbackRate;
						oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrotchet);
					}
				}
			}

			oldNote = swagNote;
		}

		unspawnedNotes.sort((a, b) -> Std.int(a.time - b.time));
		oldNote = null;
	}

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

		super.update(elapsed);
	}

	dynamic function checkNoteHitWithAI(strum:StrumNote, note:Note) {
		if (!note.canHit || note.time >= Conductor.time) return;

		final func = note.player ? noteHit : opponentNoteHit;

		// ai sustain input
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

	dynamic function sustainInputs(strum:StrumNote, note:Note) {
		var parent:Note = note.parent;

		if (!parent.canHit || parent.missed) return;

		if (!keysHeld[parent.lane] && ((parent.wasHit ? note.time < Conductor.time : parent.tooLate)) && !note.wasHit) {
			noteMiss(note);
			parent.missed = true;
			return;
		}

		if (!keysHeld[parent.lane]) return;

		note.clipToStrum(strum);

		if (note.wasHit) return;

		if (note.time <= Conductor.time) note.wasHit = true;
		else return;
		
		strum.playAnim('notePressed');
	}

	dynamic function opponentNoteHit(note:Note) {
		if (song.needsVoices && Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;
	}

	dynamic function noteHit(note:Note) {
		playerStrums.members[note.lane].playAnim('notePressed');
		note.wasHit = true;

		if (song.needsVoices) Conductor.mainVocals.volume = 1;

		totalNotesHit++;
		for (id => judge in Judgement.list) {
			if (Math.abs(note.hitTime) >= judge.timing) continue;

			score += judge.score;
			totalNotesPlayed += judge.accuracy;

			judgeSpr.display(judge.name);

			break;
		}

		combo++;
		comboNumbers.display(combo);

		updateAccuracy();
		updateScoreTxt();

		note.destroy();
		notes.remove(note);
	}

	dynamic function noteMiss(note:Note) {
		comboBreaks++;
		combo = 0;

		if (song.needsVoices) Conductor.mainVocals.volume = 0;

		updateAccuracy();
		updateScoreTxt();
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
		closeSubState();
		resetSubState();
		FlxG.camera.setFilters([]);

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		self = null;
		super.destroy();
	}
}
