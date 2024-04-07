package states.tools;

import flixel.FlxCamera;
import flixel.FlxObject;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import objects.game.Character;

import openfl.events.Event;
import openfl.events.IOErrorEvent;

import openfl.net.FileReference;

class AnimationDebug extends MusicBeatState
{
	var char:Character;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var isPlayer:Bool = false;
	var camFollow:FlxObject;

	public var camHUD:FlxCamera;
	public var camGAME:FlxCamera;

	public function new(daAnim:String = 'spooky', isPlayer:Bool)
	{
		super();
		this.daAnim = daAnim;
	}

	override function create()
	{
		changeWindowName('Animation Debug - ' + daAnim);

		camGAME = new SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGAME);
		FlxG.cameras.add(camHUD, false);

		FlxG.sound.music.stop();

		var gridBG:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(10, 10, 20, 20, true, 0xffe7e6e6, 0xffd9d5d5));
		gridBG.scrollFactor.set(0.5, 0.5);
		add(gridBG);

		char = new Character(0, 0, daAnim, isPlayer);
		char.screenCenter();
		char.debugMode = true;
		add(char);

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.scrollFactor.set();
		add(textAnim);
		textAnim.cameras = [camHUD];

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.setPosition();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		var daLoop:Int = 0;

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.scrollFactor.set();
			text.color = FlxColor.BLUE;
			dumbTexts.add(text);

			if (pushList)
				animList.push(anim);

			daLoop++;
		}
	}

	function updateTexts():Void
	{
		dumbTexts.forEach(function(text:FlxText)
		{
			text.kill();
			dumbTexts.remove(text, true);
		});
	}

	override function update(elapsed:Float)
	{
		textAnim.text = animList[curAnim];

		if (FlxG.keys.pressed.E)
			FlxG.camera.zoom += 0.005;
		if (FlxG.keys.pressed.Q)
			FlxG.camera.zoom -= 0.005;

		if (FlxG.keys.justPressed.R)
			FlxG.camera.zoom = 1;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -180;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 180;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -180;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 180;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W)
		{
			curAnim -= 1;
		}

		if (FlxG.keys.justPressed.S)
		{
			curAnim += 1;
		}

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
		{
			char.playAnim(animList[curAnim], true);

			updateTexts();
			genBoyOffsets(false);
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		if (upP || rightP || downP || leftP)
		{
			updateTexts();
			if (upP)
				char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			if (downP)
				char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			if (leftP)
				char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			if (rightP)
				char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;

			updateTexts();
			genBoyOffsets(false);
			char.playAnim(animList[curAnim], true);
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			var outputString:String = "";

			for (swagAnim in animList)
			{
				outputString += swagAnim + " " + char.animOffsets.get(swagAnim)[0] + " " + char.animOffsets.get(swagAnim)[1] + "\n";
			}

			outputString.trim();
			saveOffsets(outputString);
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new PlayState());
		}

		super.update(elapsed);
	}

	var _file:FileReference;

	private function saveOffsets(saveString:String)
	{
		if ((saveString != null) && (saveString.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(saveString, daAnim + "Offsets.txt");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}