module dvn.events;

import dvn.views.gameview;
import dvn.gamesettings;
import dvn.external;
import dvn.ui;

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
    void loadingViews(Window window) {}

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

    void addClickSafeComponents(ref Component[] components) {}

    void renderGameViewOverplayBegin(Panel overlay) {}
    void renderGameViewBackground(Image background) {}
    void renderGameViewCharacter(SceneCharacter character, Image image) {}
    void renderGameViewImage(SceneImage image, Image imageComponent) {}
    void renderGameViewAnimation(SceneAnimation animation, Animation animationComponent) {}
    void renderGameViewLabel(SceneLabel label, Label labelComponent) {}
    void renderGameViewDialoguePanelImage(RawImage image) {}
    void renderGameViewDialoguePanel(Panel panel) {}
    void renderGameViewCharacterName(SceneCharacterName characterName, Label label, Panel panel, RawImage namePanelImage) {}
    void renderGameViewOption(Label option) {}
    void renderGameViewOptionsStart() {}
    void renderGameViewOptionsFinished() {}
    void renderGameViewSaveButton(Button button) {}
    void renderGameViewExitButton(Button button) {}
    void renderGameViewSettingsButton(Button button) {}
    void renderGameViewAutoButton(Button button) {}
    void renderGameViewOverplayEnd(Panel overlay) {}
    void renderGameViewTextFinished(Label textLabel) {}

    void endGameView() {}

    // Settings View
    void renderSettingsDropDown(DropDown dropdown) {}
    void renderSettingsCheckBox(CheckBox checkbox) {}

    // Main Menu View
    void renderMainMenuView(Window window, Label titleLabel, Label playLabel, Label loadLabel, Label settingsLabel, Label exitLabel) {}

    // Video Loading View
    void renderVideoLoadingView(Video video) {}

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
