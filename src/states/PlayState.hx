package states;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;

import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;

import objects.*;
import states.stages.*;
import states.stages.objects.*;

class PlayState extends MusicBeatState {
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;
	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	var curSong:String = '';

	var songPercent:Float = 0;

	var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	var songLength:Float = 0;

	// Lua shit
	public static var instance:PlayState;

	// Less laggy controls
	var keysArray:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	public var songName:String;

	// Callbacks for stages
	public var endCallback:Void->Void = null;

	public static var nextReloadAll:Bool = false;
	override function create() {
		Paths.clearStoredMemory();
		if (nextReloadAll) {
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;

		super.create();

		endCallback = endSong;

		// for lua
		instance = this;

		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		if (Conductor.inst != null)
			Conductor.inst.stop();

		// Gameplay settings
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.setBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(noteGroup);

		noteGroup.add(opponentStrums);
		noteGroup.add(playerStrums);
		noteGroup.add(strumLineNotes);

		generateSong();
		generateStaticArrows(0);
		generateStaticArrows(1);
		noteTypes = null;

		noteGroup.cameras = [camHUD];

		startingSong = true;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if (ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		if (!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');
		
		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		Conductor.play();
	}

	function set_songSpeed(value:Float):Float {
		if (generatedMusic) {
			var ratio:Float = value / songSpeed; //funny word huh
			if (ratio != 1) {
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrotchet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float {
		#if FLX_PITCH
		if (generatedMusic) {
			Conductor.rate = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if (ratio != 1) {
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}

		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public static var startOnTime:Float = 0;

	public function clearNotesBefore(time:Float) {
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	private var noteTypes:Array<String> = [];
	private var totalColumns:Int = 4;

	private function generateSong():Void {
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch (songSpeedType) {
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		Conductor.mainVocals = new FlxSound();
		Conductor.opponentVocals = new FlxSound();
		try {
			if (songData.needsVoices) {
				var playerVocals = Paths.voices(songData.song, 'Player');
				Conductor.mainVocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
				
				var oppVocals = Paths.voices(songData.song, 'Opponent');
				if (oppVocals != null && oppVocals.length > 0) Conductor.opponentVocals.loadEmbedded(oppVocals);
			}
		} catch (e:Dynamic) {}

		Conductor.vocals.play();

		#if FLX_PITCH
		Conductor.vocals.pitch = playbackRate;
		Conductor.opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(Conductor.mainVocals);
		FlxG.sound.list.add(Conductor.opponentVocals);

		try {
			Conductor.inst = FlxG.sound.load(Paths.inst(songData.song));
			Conductor.inst.onComplete = endCallback;
		} catch (e:Dynamic) {}

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		var oldNote:Note = null;
		var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
		var ghostNotesCaught:Int = 0;
		var daBpm:Float = Conductor.bpm;
	
		for (section in sectionsData) {
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
				daBpm = section.bpm;

			for (i in 0...section.sectionNotes.length) {
				final songNotes:Array<Dynamic> = section.sectionNotes[i];
				var spawnTime:Float = songNotes[0];
				var noteColumn:Int = Std.int(songNotes[1] % totalColumns);
				var holdLength:Float = songNotes[2];
				var noteType:String = songNotes[3];
				if (Math.isNaN(holdLength))
					holdLength = 0.0;

				var gottaHitNote:Bool = (songNotes[1] < totalColumns);

				if (i != 0) {
					// CLEAR ANY POSSIBLE GHOST NOTES
					for (evilNote in unspawnNotes) {
						var matches: Bool = (noteColumn == evilNote.lane && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
						if (matches && Math.abs(spawnTime - evilNote.strumTime) == 0.0) {
							evilNote.destroy();
							unspawnNotes.remove(evilNote);
							ghostNotesCaught++;
						}
					}
				}

				var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);
				var isAlt: Bool = section.altAnim && !gottaHitNote;
				swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
				swagNote.animSuffix = isAlt ? "-alt" : "";
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = holdLength;
				swagNote.noteType = noteType;
	
				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var curstepCrotchet:Float = 60 / daBpm * 1000 / 4.0;
				final roundSus:Int = Math.round(swagNote.sustainLength / curstepCrotchet);
				if (roundSus > 0) {
					for (susNote in 0...roundSus) {
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(spawnTime + (curstepCrotchet * susNote), noteColumn, oldNote, true);
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if (!isPixelStage) {
							if (oldNote.isSustainNote) {
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.resizeByRatio(curstepCrotchet / Conductor.stepCrotchet);
							}

							if (ClientPrefs.data.downScroll) sustainNote.correctionOffset = 0;
						} else if (oldNote.isSustainNote) {
							oldNote.scale.y /= playbackRate;
							oldNote.resizeByRatio(curstepCrotchet / Conductor.stepCrotchet);
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if (ClientPrefs.data.middleScroll) {
							sustainNote.x += 310;
							if (noteColumn > 1) sustainNote.x += FlxG.width / 2 + 25; //Up and Right	
						}
					}
				}

				if (swagNote.mustPress) swagNote.x += FlxG.width / 2; // general offset
				else if (ClientPrefs.data.middleScroll) {
					swagNote.x += 310;
					if (noteColumn > 1) { //Up and Right
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if (!noteTypes.contains(swagNote.noteType)) noteTypes.push(swagNote.noteType);
				oldNote = swagNote;
			}
		}

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4) {
			var targetAlpha:Float = 1;
			if (player < 1) {
				if (!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if (ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1) playerStrums.add(babyArrow);
			else {
				if (ClientPrefs.data.middleScroll) {
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}

	override function closeSubState() {
		super.closeSubState();
		
		if (paused) {
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = true);

			paused = false;
		}
	}

	public var paused:Bool = false;
	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (unspawnNotes[0] != null) {
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.time < time) {
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (!inCutscene) {
			if (!cpuControlled) keysCheck();

			if (notes.length > 0) {
				var fakeCrotchet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note) {
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if (!daNote.mustPress) strumGroup = opponentStrums;

					var strum:StrumNote = strumGroup.members[daNote.lane];
					daNote.followStrumNote(strum, fakeCrotchet, songSpeed / playbackRate);

					if (!daNote.mustPress && (daNote.strumTime <= Conductor.time)) opponentNoteHit(daNote);

					if (daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

					// Kill extremely late notes and cause misses
					if (Conductor.time - daNote.strumTime > noteKillOffset) {
						if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
							noteMiss(daNote);

						daNote.active = daNote.visible = false;
						invalidateNote(daNote);
					}
				});
			} else {
				notes.forEachAlive(function(daNote:Note) {
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}

		#if debug
		if (!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				killNotes();
				endCallback();
			}

			if (FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.time + 10000);
				clearNotesBefore(Conductor.time);
			}
		}
		#end
	}

	public function setSongTime(time:Float) {
		Conductor.pause();
		
		Conductor.inst.time = time - Conductor.offset;
		for (vocal in Conductor.vocals.members) {
			if (Conductor.time > vocal.length) return;
			vocal.time = time - Conductor.offset;
		}

		Conductor.rate = playbackRate;
		Conductor.time = time;
		Conductor.resume();
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void {
		Conductor.volume = 0;
		Conductor.vocals.pause();

		if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) endCallback();
		else finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset * 0.001, function(_) endCallback());
	}


	public var transitioning = false;
	public function endSong() {
		endingSong = true;

		seenCutscene = false;
		playbackRate = 1;

		if (isStoryMode) {
			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0) {
				Mods.loadTopMod();
				Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0.7, true);
				Conductor.inst.play();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				MusicBeatState.switchState(new StoryMenuState());
				if (!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
					StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

					FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
					FlxG.save.flush();
				}
				changedDifficulty = false;
			} else {
				var difficulty:String = Difficulty.getFilePath();

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
				Conductor.stop();

				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new PlayState(), false, false);
			}
		} else {
			Mods.loadTopMod();
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

			MusicBeatState.switchState(new FreeplayState());
			Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0.7, true);
			Conductor.inst.play();
			changedDifficulty = false;
		}

		transitioning = true;

		return true;
	}

	public function killNotes() {
		while (notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
	}

	public var noteGroup:FlxTypedGroup<FlxBasic>;

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode) {
			if (key == -1) return;
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			keyPressed(key);
		}
	}

	private function keyPressed(key:Int) {
/*		if (cpuControlled || key >= playerStrums.length || endingSong) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.time;
		if (Conductor.time >= 0) Conductor.time = Conductor.inst.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = n != null && !strumsBlocked[n.lane] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return canHit && !n.isSustainNote && n.lane == key;
		});

		plrInputNotes.sort(sortHitNotes);

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.lane == funnyNote.lane) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0) invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime) {
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		} else if (!ClientPrefs.data.ghostTapping) noteMissPress(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.time = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}*/
	}

	public static function sortHitNotes(a:Note, b:Note):Int {
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int) {
		if (cpuControlled || key < 0 || key >= playerStrums.length) return;

		var spr:StrumNote = playerStrums.members[key];
		if (spr != null) {
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int {
		if (key != NONE) {
			for (i in 0...arr.length) {
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note) if (key == noteKey) return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void {
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray) {
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if (pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (!inCutscene && generatedMusic) {
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.lane] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.lane];

						if (!released) goodNoteHit(n);
					}
				}
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if ((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if (releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.lane == note.lane && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.lane, daNote);
	}

	function noteMissPress(direction:Int = 1):Void { //You pressed a key when there was no notes to press for this key
		if (ClientPrefs.data.ghostTapping) return;

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	function noteMissCommon(direction:Int, note:Note = null) {
		// score and data
		var subtract:Float = 0;
		if (note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if (note.tail.length > 0) {
				note.alpha = 0.35;
				for (childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -Tahir
			}

			if (note.missed)
				return;
		}

		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed) return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}
	}

	function opponentNoteHit(note:Note):Void {
		strumPlayAnim(true, note.lane, Conductor.stepCrotchet * 1.25 * 0.001 / playbackRate);
		note.hitByOpponent = true;

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void {
		if (note.wasGoodHit) return;
		if (cpuControlled && note.ignoreNote) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = note.lane;
		var leType:String = note.noteType;

		note.wasGoodHit = true;

		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if (!note.hitCausesMiss) { //Common notes
			if (!cpuControlled) {
				var spr = playerStrums.members[note.lane];
				if (spr != null) spr.playAnim('confirm', true);
			} else strumPlayAnim(false, note.lane, Conductor.stepCrotchet * 1.25 * 0.001 / playbackRate);

			var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
			if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
			//if (gainHealth) health += note.hitHealth * healthGain;
		} else { //Notes that count as a miss if you hit them (Hurt notes for example)
			noteMiss(note);
			if (!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
		}

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if (note == null) return;

		var strum:StrumNote = playerStrums.members[note.lane];
		if (strum != null) spawnNoteSplash(note, strum);
	}

	public function spawnNoteSplash(note:Note, strum:StrumNote) {
		var splash:NoteSplash = new NoteSplash();
		splash.babyArrow = strum;
		splash.spawnSplashNote(note);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		closeSubState();
		resetSubState();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.setFilters([]);

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		backend.NoteTypesConfig.clearNoteTypesData();

		NoteSplash.configs.clear();
		instance = null;
		super.destroy();
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = (isDad ? opponentStrums : playerStrums).members[id];
		if (spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}
}
