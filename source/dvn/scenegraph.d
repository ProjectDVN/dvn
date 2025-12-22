module dvn.scenegraph;

import dvn.views.consoleview;

/// 
public final class SceneEntry
{
	public:
	final:
/// 
	bool hasRuby;
/// 
	string[] meta;
/// 
	string original;
/// 
	string name;
/// 
	string act;
/// 
	string actContinueButton;
/// 
	string music;
/// 
	string sound;
/// 
	string voice;
/// 
	bool fadeMusic;
/// 
	string background;
/// 
	SceneLabel[] labels;
/// 
	SceneCharacter[] characters;
/// 
	SceneCharacterName[] characterNames;
/// 
	SceneImage[] images;
/// 
	SceneVideo[] videos;
/// 
	SceneAnimation[] animations;
/// 
	SceneEffect[] effects;
/// 
	string textColor;
/// 
	string textFont;
/// 
	string text;
/// 
	string nextScene;
/// 
	SceneOption[] options;
/// 
	string view;
/// 
	bool hideDialogue;
/// 
	bool hideButtons;
/// 
	bool isNarrator;
/// 
	int narratorX;
/// 
	int narratorY;
/// 
	int chance;
/// 
	bool stopMusic;
/// 
	bool stopSound;
/// 
	int delay;
/// 
	SceneCharacter[] copyCharacters()
	{
		SceneCharacter[] chs = [];

		foreach (character; characters)
		{
			auto ch = new SceneCharacter;
			ch.name = character.name;
			ch.image = character.image;
			ch.position = character.position;
			ch.x = character.x;
			ch.y = character.y;
			ch.zIndex = character.zIndex;

			chs ~= ch;
		}

		return chs;
	}

/// 
	void log()
	{
		string info = "";

		if (text)
		{
			info ~= text ~ " ";
		}

		if (options)
		{
			foreach (option; options)
			{
				info ~= "[" ~ option.text ~ "] ";
			}
		}

		if (info.length)
		{
			logInfo("Scene-Entry: %s", info);
		}
	}
}

/// 
public final class SceneEffect
{
	public:
	final:
/// 
	string id;
/// 
	string[] values;
/// 
	string render;
}

/// 
public final class SceneLabel
{
	public:
	final:
/// 
	string text;
/// 
	size_t fontSize;
/// 
	int x;
/// 
	int y;
/// 
	string color;
}

public final class SceneCharacter
{
	public:
	final:
/// 
	string name;
/// 
	string image;
/// 
	string position;
/// 
	int x;
/// 
	int y;
/// 
	string movement;
/// 
	int movementSpeed;
/// 
	bool characterFadeIn;
/// 
	int zIndex;

/// 
	SceneCharacter copyCharacter()
	{
		auto c = new SceneCharacter();
		c.name = name;
		c.image = image;
		c.position = position;
		c.x = x;
		c.y = y;
		c.movement = movement;
		c.movementSpeed = movementSpeed;
		c.characterFadeIn = characterFadeIn;
		c.zIndex = zIndex;
		return c;
	}

	override int opCmp(Object o)
	{
		auto ch = cast(SceneCharacter)o;

		if (!ch)
		{
			return -1;
		}

		if (ch.zIndex == zIndex)
		{
			return 0;
		}

		if (ch.zIndex < zIndex)
		{
			return -1;
		}

		return 1;
	}

	/// Operator overload.
	override bool opEquals(Object o)
	{
		return opCmp(o) == 0;
	}
}

/// 
public final class SceneCharacterName
{
	public:
	final:
/// 
	string name;
/// 
	string color;
/// 
	string position;
}

/// 
public final class SceneOption
{
	public:
	final:
/// 
	string text;
/// 
	string nextScene;
/// 
	int chance;
}

/// 
public final class SceneImage
{
	public:
	final:
/// 
	string source;
/// 
	int x;
/// 
	int y;
/// 
	string position;
}

/// 
public final class SceneVideo
{
	public:
	final:
/// 
	string source;
/// 
	int x;
/// 
	int y;
/// 
	int width;
/// 
	int height;
/// 
	string position;
}

/// 
public final class SceneAnimation
{
	public:
	final:
/// 
	string source;
/// 
	int x;
/// 
	int y;
/// 
	string position;
/// 
	bool repeat;
}