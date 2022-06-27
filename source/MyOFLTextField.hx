package;

import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;

class MyOFLTextField extends TextField
{
	public function new()
	{
		super();
		#if html5
		removeEventListener(KeyboardEvent.KEY_DOWN, this_onKeyDown);
		addEventListener(KeyboardEvent.KEY_DOWN, this_onKeyDown, false, 1);
		#end
	}

	#if html5
	@:noCompletion override private function this_onKeyDown(event:KeyboardEvent):Void
	{
		super.this_onKeyDown(event);
		switch (event.keyCode)
		{
			case FlxKey.SPACE:
				var pos = caretIndex;
				text = text.substring(0, pos) + " " + text.substring(pos);
				setSelection(pos+1, pos+1);
			
			case FlxKey.LEFT:
				var pos = (caretIndex-1) >= 0 ? caretIndex - 1 : 0;
				setSelection(pos, pos);
				#if debug
				trace(caretIndex);
				#end
			case FlxKey.RIGHT:
				var pos = (caretIndex + 1) < text.length ? caretIndex + 1 : text.length;
				setSelection(pos, pos);
			case FlxKey.UP:
				// trace('[OpenFL Bug] Moving cursor up does not seem to work in html5 targets');
				_moveUp();
			case FlxKey.DOWN:
				// trace('[OpenFL Bug] Moving cursor down does not seem to work in html5 targets');
				_moveDown();
			default:
		}
	}

	function _moveUp()
	{
		var pos = caretIndex;
		var line_start_index = text.substring(0, pos).lastIndexOf('\n');
		var lineoffset = pos - line_start_index;
		var prev_line_start_index = text.substring(0, line_start_index).lastIndexOf('\n');
		pos = Math.floor(Math.min(prev_line_start_index + lineoffset, line_start_index - 1));
		pos = Math.floor(Math.max(pos, 0));
		setSelection(pos, pos);
	}

	function _moveDown()
	{
		var pos = caretIndex;
		var line_start_index = text.substring(0, pos).lastIndexOf('\n');
		var lineoffset = pos - line_start_index;
		var line_end = text.indexOf('\n', pos);
		pos = Math.floor(Math.min(line_end + lineoffset, text.indexOf('\n', line_end+1)));
		pos = Math.floor(Math.min(pos, text.length));
		if(pos < 0)
			pos = text.length;
		setSelection(pos, pos);
	}
	#end
}