module dvn.events;

import zid;

import dvn.views.gameview;
import dvn.gamesettings;

private DvnEvents _events;

public class DvnEvents
{
    protected:
    this() {}

    public:
    // Global
    void loadingGame() {}
    void loadedGame() {}
    void savingGame(SaveFile[string] saves, SaveFile saveFile) {}

    // Act View
    void beginActView(string actName, string continueText, string background, string sceneName) {}

    void renderActBackgroundImage(Image image) {}
    void renderActTitleLabel(Label label) {}
    void renderActBeginLabel(Label label) {}

    void endActView() {}

    // Game View
    void loadingGameScripts() {}
    void loadedGameScripts(SceneEntry[string] scenes) {}
    
    void beginGameView(string sceneName, string loadBackground, string loadMusic) {}
    
    void beginHandleScene(SceneEntry scene, SceneEntry nextScene, bool isEnding) {}
    
    void playingMusic(string music) {}
    void playingSound(string sound) {}

    void renderGameViewOverplayBegin(Panel overlay) {}
    void renderGameViewBackground(Image background) {}
    void renderGameViewCharacter(SceneCharacter character, Image image) {}
    void renderGameViewImage(SceneImage image, Image imageComponent) {}
    void renderGameViewAnimation(SceneAnimation animation, Animation animationComponent) {}
    void renderGameViewDialoguePanel(Panel panel) {}
    void renderGameViewCharacterName(SceneCharacterName characterName, Label label, Panel panel) {}
    void renderGameViewOption(Label option) {}
    void renderGameViewSaveButton(Button button) {}
    void renderGameViewExitButton(Button button) {}
    void renderGameViewSettingsButton(Button button) {}
    void renderGameViewOverplayEnd(Panel overlay) {}

    void endGameView() {}

    // Settings View
    void renderSettingsDropDown(DropDown dropdown) {}

    static:
    final:
    void setEvents(DvnEvents events)
    {
        _events = events;
    }

    DvnEvents getEvents()
    {
        if (!_events)
        {
            _events = new DvnEvents;
        }

        return _events;
    }
}


