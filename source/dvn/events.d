/**
* Copyright (c) 2025 Project DVN
*/
module dvn.events;

import dvn.views.gameview;
import dvn.gamesettings;
import dvn.external;
import dvn.ui;
import dvn.application;
import dvn.window;
import dvn.resources;

private DvnEvents[] _eventsHub;
private DvnEvents _events;

public class DvnEvents
{
    protected:
    this() {}

    public:
    // Global
    ubyte[] scriptBundleWrite(ubyte[] buffer) { return buffer; }
    ubyte[] scriptBundleRead(ubyte[] buffer) { return buffer; }

    void loadedExternalApplicationState() {} // Ex. SDL has been initialized, do whatever the fuck you want with this
    void loadedSettings(GameSettings settings) {}
    void fontsLoaded(Application app) {}
    void standardEffectsLoaded() {}

    void loadingAllResources(Resource[string] resources) {}
    void loadingResource(string key, Resource resource) {}
    void loadedResource(string key, Resource resource) {}
    void loadedAllResources() {}
    void engineReady(Application app, Window[] windows) {}

    void preFrameLoop(Window[] windows) {}
    void preRenderFrameLoop(Window[] windows) {}
    void postRenderFrameLoop(Window[] windows) {}
    void postFrameLoop(Window[] windows) {}
    void preRenderContent(Window window) {}
    void postRenderContent(Window window) {}
    void loadingGame() {}
    void loadedGame() {}
    void savingGame(SaveFile[string] saves, SaveFile saveFile) {}
    void loadingViews(Window window) {}
    void onViewChange(View oldView, View newView, string oldViewName, string newViewName) {}

    // Act View
    void beginActView(string actName, string continueText, string background, string sceneName) {}

    void renderActBackgroundImage(Image image) {}
    void renderActTitleLabel(Label label) {}
    void renderActBeginLabel(Label label) {}

    void endActView() {}

    // Game View
    void loadingGameScripts() {}
    bool injectGameScript(SceneEntry scene, string key, string[] keyData, string value) { return true; }
    void loadedGameScripts(SceneEntry[string] scenes) {}
    
    void beginGameView(string sceneName, string loadBackground, string loadMusic) {}
    
    void beginHandleScene(SceneEntry scene, SceneEntry nextScene, bool isEnding) {}
    
    void playingMusic(string music) {}
    void playingSound(string sound) {}

    void addClickSafeComponents(ref Component[] components) {}

    // Background has been rendered, nothing else
    void onEffectPre(SceneEffect effect) {}
    // Every component has been or is being rendered (text is delayed so it might not be finished)
    void onEffectPost(SceneEffect effect) {}

    void renderGameViewOverplayBegin(Panel overlay) {}
    void renderGameViewBackground(Image background) {}
    void renderGameViewCharacter(SceneCharacter character, Image image) {}
    void renderGameViewImage(SceneImage image, Image imageComponent) {}
    void renderGameViewVideo(SceneVideo video, Video videoComponent) {}
    void renderGameViewAnimation(SceneAnimation animation, Animation animationComponent) {}
    void renderGameViewLabel(SceneLabel label, Label labelComponent) {}
    void renderGameViewDialoguePanelImage(RawImage image) {}
    void renderGameViewDialoguePanel(Panel panel) {}
    void renderGameViewCharacterName(SceneCharacterName characterName, Label label, Panel panel, RawImage namePanelImage) {}
    void renderGameViewOption(Label option) {}
    void renderGameViewOption(Button option) {}
    void renderGameViewOptionsStart() {}
    void renderGameViewOptionsFinished() {}
    void renderGameViewSaveButton(Button button) {}
    void renderGameViewExitButton(Button button) {}
    void renderGameViewSettingsButton(Button button) {}
    void renderGameViewAutoButton(Button button) {}
    void renderGameViewQuickSaveButton(Button button) {}
    void renderGameViewOverplayEnd(Panel overlay) {}
    void renderGameViewTextStart(SceneEntry scene) {}
    void renderGameViewTextFinished(Label textLabel) {}

    bool onGameViewOptionClick(Label option) { return true; }
    bool onGameViewOptionClick(Button option) { return true; }

    void endGameView() {}

    // Settings View
    void renderSettingsDropDown(DropDown dropdown) {}
    void renderSettingsCheckBox(CheckBox checkbox) {}

    // Main Menu View
    void renderMainMenuView(Window window, Component titleLabel, Component playLabel, Component loadLabel, Component historyLabel, Component settingsLabel, Component galleryLabel, Component exitLabel) {}

    // Video Loading View
    void renderVideoLoadingView(Video video) {}

    // Load Game View
    void renderLoadGameViewPrevLabel(Label label) {}
    void renderLoadGameViewNextLabel(Label label) {}
    void renderLoadGameViewLoadEntry(SaveFile saveFile, RawImage image, Label saveLabel) {}

    static:
    final:
    void setEvents(DvnEvents events)
    {
        _eventsHub ~= events;

        class EventBuilder : DvnEvents
        {
            public override ubyte[] scriptBundleWrite(ubyte[] buffer)
            {
                foreach (ev; _eventsHub)
                {
                    buffer = ev.scriptBundleWrite(buffer);
                }

                return buffer;
            }

            public override ubyte[] scriptBundleRead(ubyte[] buffer)
            {
                foreach (ev; _eventsHub)
                {
                    buffer = ev.scriptBundleRead(buffer);
                }

                return buffer;
            }

            public override void loadedExternalApplicationState()
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadedExternalApplicationState();
                }
            }
            public override void loadedSettings(GameSettings settings)
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadedSettings(settings);
                }
            }
            public override void fontsLoaded(Application app)
            {
                foreach (ev; _eventsHub)
                {
                    ev.fontsLoaded(app);
                }
            }
            public override void standardEffectsLoaded()
            {
                foreach (ev; _eventsHub)
                {
                    ev.standardEffectsLoaded();
                }
            }

            public override void loadingAllResources(Resource[string] resources)
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadingAllResources(resources);
                }
            }
            public override void loadingResource(string key, Resource resource)
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadingResource(key, resource);
                }
            }
            public override void loadedResource(string key, Resource resource)
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadedResource(key, resource);
                }
            }
            public override void loadedAllResources()
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadedAllResources();
                }
            }
            public override void engineReady(Application app, Window[] windows)
            {
                foreach (ev; _eventsHub)
                {
                    ev.engineReady(app, windows);
                }
            }

            public override void preFrameLoop(Window[] windows)
            {
                foreach (ev; _eventsHub)
                {
                    ev.preFrameLoop(windows);
                }
            }

            public override void preRenderFrameLoop(Window[] windows)
            {
                foreach (ev; _eventsHub)
                {
                    ev.preRenderFrameLoop(windows);
                }
            }

            public override void postRenderFrameLoop(Window[] windows)
            {
                foreach (ev; _eventsHub)
                {
                    ev.postRenderFrameLoop(windows);
                }
            }

            public override void postFrameLoop(Window[] windows)
            {
                foreach (ev; _eventsHub)
                {
                    ev.postFrameLoop(windows);
                }
            }

            public override void preRenderContent(Window window)
            {
                foreach (ev; _eventsHub)
                {
                    ev.preRenderContent(window);
                }
            }

            public override void postRenderContent(Window window)
            {
                foreach (ev; _eventsHub)
                {
                    ev.postRenderContent(window);
                }
            }

            public override void loadingGame()
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadingGame();
                }
            }

            public override void loadedGame()
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadedGame();
                }
            }

            public override void savingGame(SaveFile[string] saves, SaveFile saveFile)
            {
                foreach (ev; _eventsHub)
                {
                    ev.savingGame(saves, saveFile);
                }
            }

            public override void loadingViews(Window window)
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadingViews(window);
                }
            }

            public override void onViewChange(View oldView, View newView, string oldViewName, string newViewName)
            {
                foreach (ev; _eventsHub)
                {
                    ev.onViewChange(oldView, newView, oldViewName, newViewName);
                }
            }

            // Act View
            public override void beginActView(string actName, string continueText, string background, string sceneName)
            {
                foreach (ev; _eventsHub)
                {
                    ev.beginActView(actName, continueText, background, sceneName);
                }
            }

            public override void renderActBackgroundImage(Image image)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderActBackgroundImage(image);
                }
            }

            public override void renderActTitleLabel(Label label)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderActTitleLabel(label);
                }
            }

            public override void renderActBeginLabel(Label label)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderActBeginLabel(label);
                }
            }

            public override void endActView()
            {
                foreach (ev; _eventsHub)
                {
                    ev.endActView();
                }
            }

            // Game View
            public override void loadingGameScripts()
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadingGameScripts();
                }
            }

            public override bool injectGameScript(SceneEntry scene, string key, string[] keyData, string value)
            {
                bool handled = false;
                foreach (ev; _eventsHub)
                {
                    if (ev.injectGameScript(scene, key, keyData, value))
                    {
                        handled = true;
                    }
                }
                return handled;
            }

            public override void loadedGameScripts(SceneEntry[string] scenes)
            {
                foreach (ev; _eventsHub)
                {
                    ev.loadedGameScripts(scenes);
                }
            }

            public override void beginGameView(string sceneName, string loadBackground, string loadMusic)
            {
                foreach (ev; _eventsHub)
                {
                    ev.beginGameView(sceneName, loadBackground, loadMusic);
                }
            }

            public override void beginHandleScene(SceneEntry scene, SceneEntry nextScene, bool isEnding)
            {
                foreach (ev; _eventsHub)
                {
                    ev.beginHandleScene(scene, nextScene, isEnding);
                }
            }

            public override void playingMusic(string music)
            {
                foreach (ev; _eventsHub)
                {
                    ev.playingMusic(music);
                }
            }

            public override void playingSound(string sound)
            {
                foreach (ev; _eventsHub)
                {
                    ev.playingSound(sound);
                }
            }

            public override void addClickSafeComponents(ref Component[] components)
            {
                foreach (ev; _eventsHub)
                {
                    ev.addClickSafeComponents(components);
                }
            }

            // Background has been rendered, nothing else
            public override void onEffectPre(SceneEffect effect)
            {
                foreach (ev; _eventsHub)
                {
                    ev.onEffectPre(effect);
                }
            }

            // Every component has been or is being rendered (text is delayed so it might not be finished)
            public override void onEffectPost(SceneEffect effect)
            {
                foreach (ev; _eventsHub)
                {
                    ev.onEffectPost(effect);
                }
            }

            public override void renderGameViewOverplayBegin(Panel overlay)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewOverplayBegin(overlay);
                }
            }

            public override void renderGameViewBackground(Image background)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewBackground(background);
                }
            }

            public override void renderGameViewCharacter(SceneCharacter character, Image image)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewCharacter(character, image);
                }
            }

            public override void renderGameViewImage(SceneImage image, Image imageComponent)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewImage(image, imageComponent);
                }
            }

            public override void renderGameViewVideo(SceneVideo video, Video videoComponent)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewVideo(video, videoComponent);
                }
            }

            public override void renderGameViewAnimation(SceneAnimation animation, Animation animationComponent)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewAnimation(animation, animationComponent);
                }
            }

            public override void renderGameViewLabel(SceneLabel label, Label labelComponent)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewLabel(label, labelComponent);
                }
            }

            public override void renderGameViewDialoguePanelImage(RawImage image)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewDialoguePanelImage(image);
                }
            }

            public override void renderGameViewDialoguePanel(Panel panel)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewDialoguePanel(panel);
                }
            }

            public override void renderGameViewCharacterName(SceneCharacterName characterName, Label label, Panel panel, RawImage namePanelImage)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewCharacterName(characterName, label, panel, namePanelImage);
                }
            }

            public override void renderGameViewOption(Label option)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewOption(option);
                }
            }

            public override void renderGameViewOption(Button option)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewOption(option);
                }
            }

            public override void renderGameViewOptionsStart()
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewOptionsStart();
                }
            }

            public override void renderGameViewOptionsFinished()
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewOptionsFinished();
                }
            }

            public override void renderGameViewSaveButton(Button button)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewSaveButton(button);
                }
            }

            public override void renderGameViewExitButton(Button button)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewExitButton(button);
                }
            }

            public override void renderGameViewSettingsButton(Button button)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewSettingsButton(button);
                }
            }

            public override void renderGameViewAutoButton(Button button)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewAutoButton(button);
                }
            }

            public override void renderGameViewQuickSaveButton(Button button)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewQuickSaveButton(button);
                }
            }

            public override void renderGameViewOverplayEnd(Panel overlay)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewOverplayEnd(overlay);
                }
            }

            public override void renderGameViewTextStart(SceneEntry scene)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewTextStart(scene);
                }
            }

            public override void renderGameViewTextFinished(Label textLabel)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderGameViewTextFinished(textLabel);
                }
            }

            public override bool onGameViewOptionClick(Label option)
            {
                bool result = true;
                foreach (ev; _eventsHub)
                {
                    if (!ev.onGameViewOptionClick(option))
                    {
                        result = false;
                    }
                }
                return result;
            }

            public override bool onGameViewOptionClick(Button option)
            {
                bool result = true;
                foreach (ev; _eventsHub)
                {
                    if (!ev.onGameViewOptionClick(option))
                    {
                        result = false;
                    }
                }
                return result;
            }

            public override void endGameView()
            {
                foreach (ev; _eventsHub)
                {
                    ev.endGameView();
                }
            }

            // Settings View
            public override void renderSettingsDropDown(DropDown dropdown)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderSettingsDropDown(dropdown);
                }
            }

            public override void renderSettingsCheckBox(CheckBox checkbox)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderSettingsCheckBox(checkbox);
                }
            }

            // Main Menu View
            public override void renderMainMenuView(Window window, Component titleLabel, Component playLabel, Component loadLabel, Component historyLabel, Component settingsLabel, Component galleryLabel, Component exitLabel)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderMainMenuView(window, titleLabel, playLabel, loadLabel, historyLabel, settingsLabel, galleryLabel, exitLabel);
                }
            }

            // Video Loading View
            public override void renderVideoLoadingView(Video video)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderVideoLoadingView(video);
                }
            }

            // Load Game View
            public override void renderLoadGameViewPrevLabel(Label label)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderLoadGameViewPrevLabel(label);
                }
            }

            public override void renderLoadGameViewNextLabel(Label label)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderLoadGameViewNextLabel(label);
                }
            }

            public override void renderLoadGameViewLoadEntry(SaveFile saveFile, RawImage image, Label saveLabel)
            {
                foreach (ev; _eventsHub)
                {
                    ev.renderLoadGameViewLoadEntry(saveFile, image, saveLabel);
                }
            }

            static assert(EnforceEventOverrides!(DvnEvents, EventBuilder));
        }

        _events = new EventBuilder;
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

public final class EventCollection
{
  private:
  MouseButtonEventHandler[] _mouseButtonDownEvents;
  MouseButtonEventHandler[] _mouseButtonUpEvents;
  MouseMoveEventHandler[] _mouseMoveEvents;
  TextInputEventHandler[] _textInputEvents;
  KeyboardEventHandler[] _keyboardDownEvents;
  KeyboardEventHandler[] _keyboardUpEvents;
  size_t[size_t] _eventIds;

  public:
  final:
  this()
  {
    clearEvents();
  }

  package(dvn)
  {
    void clearEvents()
    {
      _mouseButtonDownEvents = [];
      _mouseButtonUpEvents = [];
      _mouseMoveEvents = [];
      _textInputEvents = [];
      _keyboardDownEvents = [];
      _keyboardUpEvents = [];

      if (_eventIds)
      {
        _eventIds.clear();
      }
    }

    void attachMouseButtonDownEvent(MouseButtonEventHandler eventHandler)
    {
      if (_eventIds && eventHandler._id in _eventIds)
      {
        return;
      }

      _eventIds[eventHandler._id] = eventHandler._id;

      _mouseButtonDownEvents ~= eventHandler;
    }

    void attachMouseButtonUpEvent(MouseButtonEventHandler eventHandler)
    {
      if (_eventIds && eventHandler._id in _eventIds)
      {
        return;
      }

      _eventIds[eventHandler._id] = eventHandler._id;

      _mouseButtonUpEvents ~= eventHandler;
    }

    void attachMouseMoveEvent(MouseMoveEventHandler eventHandler)
    {
      if (_eventIds && eventHandler._id in _eventIds)
      {
        return;
      }

      _eventIds[eventHandler._id] = eventHandler._id;

      _mouseMoveEvents ~= eventHandler;
    }

    void attachTextInputEvent(TextInputEventHandler eventHandler)
    {
      if (_eventIds && eventHandler._id in _eventIds)
      {
        return;
      }

      _eventIds[eventHandler._id] = eventHandler._id;

      _textInputEvents ~= eventHandler;
    }

    void attachKeyboardDownEvent(KeyboardEventHandler eventHandler)
    {
      if (_eventIds && eventHandler._id in _eventIds)
      {
        return;
      }

      _eventIds[eventHandler._id] = eventHandler._id;

      _keyboardDownEvents ~= eventHandler;
    }

    void attachKeyboardUpEvent(KeyboardEventHandler eventHandler)
    {
      if (_eventIds && eventHandler._id in _eventIds)
      {
        return;
      }

      _eventIds[eventHandler._id] = eventHandler._id;

      _keyboardUpEvents ~= eventHandler;
    }
  }

  bool fireMouseButtonDownEvent(MouseButton button, IntVector mousePosition)
  {
    if (_mouseButtonDownEvents)
    {
      foreach (mouseButtonDownEvent; _mouseButtonDownEvents)
      {
        if (!mouseButtonDownEvent(button, mousePosition))
        {
          return false;
        }
      }
    }

    return true;
  }

  bool fireMouseButtonUpEvent(MouseButton button, IntVector mousePosition)
  {
    if (_mouseButtonUpEvents)
    {
      foreach (mouseButtonUpEvent; _mouseButtonUpEvents)
      {
        if (!mouseButtonUpEvent(button, mousePosition))
        {
          return false;
        }
      }
    }

    return true;
  }

  bool fireMouseMoveEvent(IntVector mousePosition)
  {
    if (_mouseMoveEvents)
    {
      foreach (mouseMoveEvent; _mouseMoveEvents)
      {
        if (!mouseMoveEvent(mousePosition))
        {
          return false;
        }
      }
    }

    return true;
  }

  bool fireTextInputEvent(dchar unicode, dstring unicodeText)
  {
    if (_textInputEvents)
    {
      foreach (textInputEvent; _textInputEvents)
      {
        if (!textInputEvent(unicode, unicodeText))
        {
          return false;
        }
      }
    }

    return true;
  }

  bool fireKeyboardDownEvent(KeyboardKey key)
  {
    if (_keyboardDownEvents)
    {
      foreach (keyboardDownEvent; _keyboardDownEvents)
      {
        if (!keyboardDownEvent(key))
        {
          return false;
        }
      }
    }

    return true;
  }

  bool fireKeyboardUpEvent(KeyboardKey key)
  {
    if (_keyboardUpEvents)
    {
      foreach (keyboardUpEvent; _keyboardUpEvents)
      {
        if (!keyboardUpEvent(key))
        {
          return false;
        }
      }
    }

    return true;
  }
}

private size_t _eventId = 0;

public final class MouseButtonEventHandler
{
  private:
  bool delegate(MouseButton,IntVector) _handler;
  bool function(MouseButton,IntVector) _fnHandler;
  size_t _id;
  string _source;

  public:
  final:
  this(MouseButtonEventHandler handler) { _id = ++_eventId; _handler = handler._handler; _fnHandler = handler._fnHandler; }

  this(bool delegate(MouseButton,IntVector) handler) { _id = ++_eventId; _handler = handler; }

  this(bool function(MouseButton,IntVector) handler) { _id = ++_eventId; _fnHandler = handler; }

  this(void delegate(MouseButton,IntVector) handler) { this((b,p) { handler(b,p); return true; }); }

  this(void function(MouseButton,IntVector) handler) { this((b,p) { handler(b,p); return true; }); }

  bool opCall(MouseButton button, IntVector mousePosition)
  {
    if (_handler) return _handler(button,mousePosition);
    else if (_fnHandler) return _fnHandler(button,mousePosition);
    return true;
  }
}

public final class MouseMoveEventHandler
{
  private:
  bool delegate(IntVector) _handler;
  bool function(IntVector) _fnHandler;
  size_t _id;

  public:
  final:
  this(MouseMoveEventHandler handler) { _id = ++_eventId; _handler = handler._handler; _fnHandler = handler._fnHandler; }

  this(bool delegate(IntVector) handler) { _id = ++_eventId; _handler = handler; }

  this(bool function(IntVector) handler) { _id = ++_eventId; _fnHandler = handler; }

  this(void delegate(IntVector) handler) { this((p) { handler(p); return true; }); }

  this(void function(IntVector) handler) { this((p) { handler(p); return true; }); }

  bool opCall(IntVector mousePosition)
  {
    if (_handler) return _handler(mousePosition);
    else if (_fnHandler) return _fnHandler(mousePosition);
    return true;
  }
}

public final class TextInputEventHandler
{
  private:
  bool delegate(dchar,dstring) _handler;
  bool function(dchar,dstring) _fnHandler;
  size_t _id;

  public:
  final:
  this(TextInputEventHandler handler) { _id = ++_eventId; _handler = handler._handler; _fnHandler = handler._fnHandler; }

  this(bool delegate(dchar,dstring) handler) { _id = ++_eventId; _handler = handler; }

  this(bool function(dchar,dstring) handler) { _id = ++_eventId; _fnHandler = handler; }

  this(void delegate(dchar,dstring) handler) { this((c,s) { handler(c,s); return true; }); }

  this(void function(dchar,dstring) handler) { this((c,s) { handler(c,s); return true; }); }

  bool opCall(dchar unicode, dstring unicodeText)
  {
    if (_handler) return _handler(unicode,unicodeText);
    else if (_fnHandler) return _fnHandler(unicode,unicodeText);
    return true;
  }
}

public final class KeyboardEventHandler
{
  private:
  bool delegate(KeyboardKey) _handler;
  bool function(KeyboardKey) _fnHandler;
  size_t _id;

  public:
  final:
  this(KeyboardEventHandler handler) { _id = ++_eventId; _handler = handler._handler; _fnHandler = handler._fnHandler; }

  this(bool delegate(KeyboardKey) handler) { _id = ++_eventId; _handler = handler; }

  this(bool function(KeyboardKey) handler) { _id = ++_eventId; _fnHandler = handler; }

  this(void delegate(KeyboardKey) handler) { this((k) { handler(k); return true; }); }

  this(void function(KeyboardKey) handler) { this((k) { handler(k); return true; }); }

  bool opCall(KeyboardKey key)
  {
    if (_handler) return _handler(key);
    else if (_fnHandler) return _fnHandler(key);
    return true;
  }
}
