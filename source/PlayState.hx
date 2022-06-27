package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import haxe.Log;
import haxe.io.Bytes;
import hscript.Interp;
import hscript.Parser;
import openfl.display.Shader;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.filters.ShaderFilter;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.utils.Assets;

using StringTools;

// to store the shader code and the script
typedef CodeState = {
	shadercode:String,
	scriptcode:String
};

class PlayState extends FlxState
{
	var shadersrc_textarea:MyOFLTextField;
	var script_textarea:MyOFLTextField;
	var compileshaderbtn:FlxButton;
	var saveclearbtn:FlxButton;
	var downloadcodebtn:FlxButton;
	var loadcodebtn:FlxButton;
	var testsprite:FlxCamera;
	var shapeshader:Shader;

	// scripting stuff
	var parser:Parser;
	var interpreter:Interp;

	// code saving stuff
	var _download_fileref:FileReference;

	var vsrc = Assets.getText('assets/data/boilerplate_vertex_shader.vert');

	function add_shadersrc_label()
	{
		var label = new FlxText(0, 0, 0, "Shader Source:", 12);
		add(label);
		return label;
	}

	function shadersrc_textarea_init()
	{
		var label = add_shadersrc_label();
		shadersrc_textarea = new MyOFLTextField();
		shadersrc_textarea.background = true;
		shadersrc_textarea.backgroundColor = 0xff1e1e1e;
		shadersrc_textarea.textColor = FlxColor.WHITE;
		var txtfmt = shadersrc_textarea.getTextFormat();
		txtfmt.size = 15;
		txtfmt.font = 'Consolas';
		shadersrc_textarea.defaultTextFormat = txtfmt;
		shadersrc_textarea.type = INPUT;
		shadersrc_textarea.multiline = true;
		shadersrc_textarea.y += label.y + label.height;
		shadersrc_textarea.width = FlxG.width/2;
		shadersrc_textarea.height = FlxG.height/2 - label.height - 100;
		fillBoilerPlateShaderSource();
		FlxG.addChildBelowMouse(shadersrc_textarea);
	}

	function fillBoilerPlateShaderSource()
	{
		if(FlxG.save.data != null && FlxG.save.data.shadersrc != null)
		{
			shadersrc_textarea.text = cast FlxG.save.data.shadersrc;
		}
		else
		{
			shadersrc_textarea.text = Assets.getText('assets/data/boilerplate_fragment_shader.frag');
		}
	}

	function fillBoilerPlateScript()
	{
		if(FlxG.save.data != null && FlxG.save.data.scriptsrc != null)
		{
			script_textarea.text = cast FlxG.save.data.scriptsrc;
		}
		else
		{
			script_textarea.text = Assets.getText('assets/data/boilerplate_script.hxs');
		}
	}

	function add_script_label()
	{
		var label = new FlxText(0, shadersrc_textarea.y + shadersrc_textarea.height, 0, "Script Source:", 12);
		add(label);
		return label;
	}

	function script_textarea_init()
	{
		var label = add_script_label();
		script_textarea = new MyOFLTextField();
		script_textarea.background = true;
		script_textarea.backgroundColor = 0xff1e1e1e;
		script_textarea.textColor = FlxColor.WHITE;
		var txtfmt = script_textarea.getTextFormat();
		txtfmt.size = 15;
		txtfmt.font = 'Consolas';
		script_textarea.defaultTextFormat = txtfmt;
		script_textarea.type = INPUT;
		script_textarea.multiline = true;
		script_textarea.y = label.y + label.height;
		script_textarea.width = FlxG.width/2;
		script_textarea.height = FlxG.height/2 - 100;
		fillBoilerPlateScript();
		FlxG.addChildBelowMouse(script_textarea);
	}

	function saveAllCode()
	{
		FlxG.save.data.shadersrc = shadersrc_textarea.text;
		FlxG.save.data.scriptsrc = script_textarea.text;
		FlxG.save.flush();
	}

	function handleButtonClick()
	{
		#if debug
		trace('[DEBUG] shader source:');
		trace(Bytes.ofString(shadersrc_textarea.text));
		trace('[DEBUG] script:');
		trace(Bytes.ofString(script_textarea.text));
		#end

		// save the text u wrote so far in case the program crashes on execution
		saveAllCode();

		var newshader = new Shader();
		newshader.glVertexSource = vsrc;
		newshader.glFragmentSource = shadersrc_textarea.text;

		var ast = parser.parseString(script_textarea.text);
		interpreter.variables.set('shader', newshader);
		var result = interpreter.execute(ast);
		#if debug
		trace('[DEBUG] result: $result');
		#end
		var execute = interpreter.variables.get('execute');
		if(execute != null)
		{
			execute();
		}

		testsprite.setFilters([ new ShaderFilter(newshader) ]);
	}

	function make_compile_btn()
	{
		compileshaderbtn = new FlxButton(0, script_textarea.y + script_textarea.height, "Compile Shader and Run Script", handleButtonClick);
		compileshaderbtn.setGraphicSize(Std.int(compileshaderbtn.width) + 50, 85);
		compileshaderbtn.updateHitbox();
		for(i in 0...compileshaderbtn.labelOffsets.length)
		{
			compileshaderbtn.labelOffsets[i].add(20, 10);
		}
		compileshaderbtn.label.setFormat(null, 10, FlxColor.BLACK);
		add(compileshaderbtn);
	}

	function make_save_clear_btn()
	{
		saveclearbtn = new FlxButton(compileshaderbtn.x + compileshaderbtn.width + 5, compileshaderbtn.y, "Clear Saved code", ()->{
			FlxG.save.erase();
		});
		saveclearbtn.setGraphicSize(Std.int(saveclearbtn.width) + 50, 85);
		saveclearbtn.updateHitbox();
		for(i in 0...saveclearbtn.labelOffsets.length)
		{
			saveclearbtn.labelOffsets[i].add(20, 20);
		}
		saveclearbtn.label.setFormat(null, 10, FlxColor.BLACK);
		add(saveclearbtn);
	}

	function put_disclaimer_text()
	{
		// var disclaimer = new FlxText(loadcodebtn.x + loadcodebtn.width + 5, loadcodebtn.y, 300, "P.S: If the program crashes, just reload the page.", 10);
		var disclaimer = new FlxText(0, loadcodebtn.y + loadcodebtn.height, 500, "P.S: If the program crashes, just reload the page.", 10);
		disclaimer.text += " All your code is saved every time you click the compile button";
		disclaimer.setFormat('Consolas', 15, FlxColor.WHITE);
		disclaimer.updateHitbox();
		add(disclaimer);
	}

	function testsprite_init()
	{
		testsprite = new FlxCamera(Std.int(shadersrc_textarea.x + shadersrc_textarea.width + 3), 0, Std.int(FlxG.width/2 - 3), Std.int(FlxG.height));
		FlxG.cameras.add(testsprite, false);
		testsprite.setFilters([ new ShaderFilter(shapeshader) ]);
	}

	inline function remove_volume_controls()
	{
		FlxG.sound.muteKeys = FlxG.sound.volumeDownKeys = FlxG.sound.volumeUpKeys = null;
	}

	function script_init()
	{
		parser = new Parser();
		interpreter = new Interp();
		parser.allowTypes = true;
		
		interpreter.variables.set('FlxG', FlxG);
		interpreter.variables.set('Assets', Assets);
		interpreter.variables.set('canvas', testsprite);
		interpreter.variables.set('Reflect', Reflect);
		interpreter.variables.set('Math', Math);
		interpreter.variables.set('Std', Std);
		interpreter.variables.set('null', null);
		interpreter.variables.set('trace', Log.trace);
		interpreter.variables.set('asset_bf', 'assets/images/bf.png');
		interpreter.variables.set('asset_gf', 'assets/images/gf.png');
		interpreter.variables.set('asset_dad', 'assets/images/dadsprite.png');
	}

	function onSaveComplete(_)
	{
		_download_fileref.removeEventListener(Event.COMPLETE, onSaveComplete);
		_download_fileref.removeEventListener(Event.CANCEL, onSaveCancel);
		_download_fileref.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_download_fileref = null;
		FlxG.log.notice("Successfully saved your code");
	}

	function onSaveCancel(_)
	{
		_download_fileref.removeEventListener(Event.COMPLETE, onSaveComplete);
		_download_fileref.removeEventListener(Event.CANCEL, onSaveCancel);
		_download_fileref.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_download_fileref = null;
	}

	function onSaveError(_)
	{
		_download_fileref.removeEventListener(Event.COMPLETE, onSaveComplete);
		_download_fileref.removeEventListener(Event.CANCEL, onSaveCancel);
		_download_fileref.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_download_fileref = null;
		FlxG.log.error("Problem saving code :/");
	}

	function download_code_stuff()
	{
		var json:CodeState = {
			shadercode: shadersrc_textarea.text,
			scriptcode: script_textarea.text
		};
		var data:String = Json.stringify(json, null, ' ');

		if ((data != null) && (data.length > 0))
		{
			_download_fileref = new FileReference();
			_download_fileref.addEventListener(Event.COMPLETE, onSaveComplete);
			_download_fileref.addEventListener(Event.CANCEL, onSaveCancel);
			_download_fileref.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_download_fileref.save(data.trim(), "ShaderPlayground_Code.json");
		}
	}

	function make_download_code_btn()
	{
		downloadcodebtn = new FlxButton(saveclearbtn.x + saveclearbtn.width + 5, saveclearbtn.y, "Download Current code", download_code_stuff);
		downloadcodebtn.setGraphicSize(Std.int(downloadcodebtn.width), 85);
		downloadcodebtn.updateHitbox();
		for(i in 0...downloadcodebtn.labelOffsets.length)
		{
			downloadcodebtn.labelOffsets[i].add(0, 20);
		}
		downloadcodebtn.label.setFormat(null, 10, FlxColor.BLACK);
		add(downloadcodebtn);
	}

	function startLoad(_)
	{
		_download_fileref.load();
	}

	function onLoadComplete(_)
	{
		#if debug
		trace(_download_fileref.data.toString());
		#end
		var jsonstring = _download_fileref.data.toString();
		if(jsonstring != null && jsonstring.length > 0)
		{
			var code_state:CodeState = cast Json.parse(jsonstring);
			shadersrc_textarea.text = code_state.shadercode;
			script_textarea.text = code_state.scriptcode;
		}
		_download_fileref.removeEventListener(Event.SELECT, startLoad);
		_download_fileref.removeEventListener(Event.COMPLETE, onLoadComplete);
		_download_fileref = null;
	}

	function loadCodeFromJson()
	{
		// re-using the same filereference cuz why not
		_download_fileref = new FileReference();
		_download_fileref.addEventListener(Event.SELECT, startLoad);
		_download_fileref.addEventListener(Event.COMPLETE, onLoadComplete);
		_download_fileref.browse([ new FileFilter("ShaderPlayground json files", "*.json") ]);
	}

	function make_load_code_btn()
	{
		loadcodebtn = new FlxButton(downloadcodebtn.x + downloadcodebtn.width + 5, downloadcodebtn.y, "Load code from Json", loadCodeFromJson);
		loadcodebtn.setGraphicSize(Std.int(loadcodebtn.width), 85);
		loadcodebtn.updateHitbox();
		for(i in 0...loadcodebtn.labelOffsets.length)
		{
			loadcodebtn.labelOffsets[i].add(0, 20);
		}
		loadcodebtn.label.setFormat(null, 10, FlxColor.BLACK);
		add(loadcodebtn);
	}

	override public function create()
	{
		super.create();

		remove_volume_controls();
		
		shadersrc_textarea_init();
		script_textarea_init();

		make_compile_btn();
		make_save_clear_btn();
		make_download_code_btn();
		make_load_code_btn();
		put_disclaimer_text();

		shapeshader = new Shader();
		shapeshader.glVertexSource = vsrc;
		shapeshader.glFragmentSource = 'void main(){ gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0); }';
		testsprite_init();
		
		// initialize scripting at the end to make sure everything is initialized and not null
		script_init();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if(interpreter != null && interpreter.variables.get('onUpdate') != null)
		{
			var onUpdate = interpreter.variables.get('onUpdate');
			onUpdate(elapsed);
		}
	}
}