#if !macro
// project specific
import backend.Util;
import backend.Conductor;
import backend.DiscordClient;
import backend.Awards;
import backend.Controls;
import backend.Settings;
import backend.Language;
import backend.Paths;
import backend.Scores;
import backend.Mods;
import backend.Song;
import backend.Difficulty;
import backend.Meta;
import objects.Alphabet;
import objects.FunkinSprite;
import states.MusicState;
import states.PlayState;
import scripting.ScriptHandler;
import scripting.*;

// flixel specific
import flixel.*;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxColor as FlxColour;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;

// haxe
import sys.FileSystem;
import sys.io.File;
import hxjson5.Json5;
import haxe.Json;

using StringTools;
#end