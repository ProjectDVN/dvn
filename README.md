# Project DVN - Visual Novel Engine

![DVN](https://i.imgur.com/l2iw53C.png "DVN")

Website: (Coming Soon)

Discord: https://discord.gg/UhetecF4US

Project DVN is a free open-source cross-platform visual novel framework and engine, written in the D programming language using SDL, and can be used freely for personal and commercial projects.

To create your first visual novel see: https://github.com/ProjectDVN/dvn/wiki/Creating-your-first-visual-novel

---

### Preview

![DVN Preview](https://i.imgur.com/F28Y9Sr.png "DVN Preview")

---

### Current Features

* Proper unicode support - Ex. Japanese, Chinese etc.
* Fully integrated UI components
* Lots of game configurations and customization
* Flexible and dynamic *"game scripting"* for creative story creation
* Native compilation
* Visual novel features like characters, dialogues, options, animations, music, sound effects etc-
* And much more ...

### Building

Please visit the example repo for guides on how to build the engine and/or how to develop your visual novel.

The repo can be found here: https://github.com/ProjectDVN/Example

### Events

To control most of the engine there are a set of events that can be called.

Simply define a class like below:

```d
public final class Events : DvnEvents
{
	import zid;
	import dvn.views.gameview;

	public:
	final:
	// override events here ...
}
```

Then override the event functions you need.

Ex.

```d
public final class Events : DvnEvents
{
	import zid;
	import dvn.views.gameview;

	public:
	final:
	override void renderGameViewCharacterName(SceneCharacterName characterName, Label label, Panel panel)
	{
		panel.position = IntVector(150, 150); // The name panel will always be displayed at 150x150
	}
}
```

Afterwards call the function `DvnEvents.setEvents(new Events);` to set the events.

This can be called in your main function (In most cases it will be called mainEx)

Full event function list:

```d
// Global
// Called when the game is loading
void loadingGame() {}
// Called when the game has loaded
void loadedGame() {}

// Act View
// Called when the act view begins to be displayed
void beginActView(string actName, string continueText, string background, string sceneName) {}

// Called when the act view background is rendered
void renderActBackgroundImage(Image image) {}
// Called when the act view title is rendered
void renderActTitleLabel(Label label) {}
// Called when the act view begin label is rendered
void renderActBeginLabel(Label label) {}

// Called when the act view has been displayed
void endActView() {}

// Game View
// Called when the scripts are loading
void loadingGameScripts() {}
// Called when the scripts has been loaded
void loadedGameScripts(SceneEntry[string] scenes) {}

// Called when a scene is being rendered
void beginGameView(string sceneName, string loadBackground, string loadMusic) {}

// Called when a scene is being handled
void beginHandleScene(SceneEntry scene, SceneEntry nextScene, bool isEnding) {}

// Called when music is being played
void playingMusic(string music) {}
// Called when sound effects are being played
void playingSound(string sound) {}

// Called when the overlay is being rendered
void renderGameViewOverplayBegin(Panel overlay) {}
// Called when the background has been rendered
void renderGameViewBackground(Image background) {}
// Called when a character has been rendered
void renderGameViewCharacter(SceneCharacter character, Image image) {}
// Called when an image has been rendered
void renderGameViewImage(SceneImage image, Image imageComponent) {}
// Called when an animation has been rendered
void renderGameViewAnimation(SceneAnimation animation, Animation animationComponent) {}
// Called when the dialogue panel has been rendered
void renderGameViewDialoguePanel(Panel panel) {}
// Called when the character name has been rendered
void renderGameViewCharacterName(SceneCharacterName characterName, Label label, Panel panel) {}
// Called when an option label has been rendered
void renderGameViewOption(Label option) {}
// Called when the save button has been rendered
void renderGameViewSaveButton(Button button) {}
// Called when the exit button has been rendered
void renderGameViewExitButton(Button button) {}
// Called when the settings button has been rendered
void renderGameViewSettingsButton(Button button) {}
// Called when the overlay has been rendered
void renderGameViewOverplayEnd(Panel overlay) {}

// Called when a scene has finished rendering
void endGameView() {}

// Settings View
// Called when a dropdown is rendered in the settings view
void renderSettingsDropDown(DropDown dropdown) {}
```