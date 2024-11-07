#if !macro
//Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

import sys.*;
import sys.io.*;

import backend.Paths;
import backend.Controls;
import backend.Util;
import states.MusicState;
import backend.Transition;
import backend.Settings;
import backend.Conductor;
import backend.BaseStage;
import backend.Difficulty;
import backend.Language;
import backend.Scores;

import backend.ui.*; //Psych-UI

import objects.Alphabet;
import objects.BGSprite;

import states.PlayState;

#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

//Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;
#end
