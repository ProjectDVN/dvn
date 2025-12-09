# Project DVN - Visual Novel Engine

![Project DVN](https://i.imgur.com/3pVO673.png "DVN")

[![DONATE](https://img.shields.io/badge/Support%20Project%20DVN-Donate-brightgreen.svg)](https://buymeacoffee.com/projectdvn)
[![OS](https://img.shields.io/badge/os-windows%20%7C%20linux%20%7C%20macos-ff69b4.svg)](https://code.dlang.org/packages/dvn)
[![Version](https://img.shields.io/github/v/release/projectdvn/dvn
)](https://github.com/ProjectDVN/dvn/releases)
[![Docs](https://img.shields.io/badge/documentation-online-blue
)](https://projectdvn.com/Docs/)
[![License](https://img.shields.io/dub/l/dvn.svg)](https://code.dlang.org/packages/dvn)


Website: https://projectdvn.com/

Wiki: https://github.com/ProjectDVN/dvn/wiki

Documentation: https://projectdvn.com/Docs/

Discord: https://discord.gg/UhetecF4US

Project DVN is a powerful, user-friendly and flexible free open-source visual novel engine written in the D programming language. It's designed to help creators craft immersive, interactive narrative experiences. Whether you're a solo storyteller, an indie developer, or a studio, Project DVN provides the tools and flexibility needed to bring your stories to life. No advanced technical skills required. Start your journey today!

## Vision

DVN exists to bring visual novel development closer to how stories are actually written.

The goal is simple:
**powerful systems, simple scripts.**

DVN aims to merge a screenplay-like scripting style with a deeply capable engine core - letting writers focus on narrative flow while still giving developers the freedom to build complex, dynamic experiences.

Ease of use for writers.  
Full power for developers.  
No limitations for creators.

## Core Philosophy

Project DVN is built from what visual novels actually do, not from what engines typically offer.

Most engines are built like this:

* Engine -> Features -> VNs must fit those features

DVN is the opposite

* Visual novels -> Real-world behavior -> DVN implements those behaviors

## Current Features

* No coding or compiling required - scripts run instantly.
* User-friendly - dive in without coding knowledge
* Custom script engine - write your scripts in a simple format that requires zero coding knowledge
* Flexible and dynamic *"game scripting"* for creative story creation
* Proper unicode support - Ex. Japanese, Chinese etc.
* Backup Font System (Automatic Fallback Fonts)
* Fully integrated UI components
  * Labels
  * Panels
  * Buttons
  * Textboxes
  * Dropdowns
  * Checkboxes
  * Scrollbars
  * Images
  * Videos
  * Animations
  * Can all be used outside of VN mode...
* Themes + Layout Generator
* Localization / i18n with template functions
* Multiple Windows Support (You can open multiple windows with application instances or even multiple vn instances)
* Hot reloading of scripts (Requires you to enter main menu however)
* Custom render functions with low-level access (OpenGL or custom rendering)
  * Allows custom render hooks for ex. 3D, 2D, custom pipelines etc.
* Lots of game configurations and customization
* Native compilation using D (Can run on anything D and SDL2 builds for - Ex. Windows, Linux, macOS etc.)
* Visual novel features like characters, dialogues, options, animations, music, sound effects etc.
* Eventhandling to allow more flexibility
  * All steps of the engine allows eventhandling, even dialogues and each dialogue component
* Develop without coding or compiling
* Networking (Allowing multiplayer VN, asset streaming etc.)
* Custom views - allowing minigames, custom UI, special game mechanics etc.
* Texture aliases - not default, but can be used
* Dynamic character models (actions, states, directions) - not default, but can be used
* Gallery
* History (Searchable) with jumping to ANY scene node (including options)
* DVN supports deterministic timelines, timeline jumping, and multiverse-based narrative exploration natively.
* Saving, loading, auto-save
* Auto-skipping
* Dom Parser (html, xml, svg etc.)
* CSS3 Selector Parser
* Markdown Parser
* Effects (Like screen shake) + Custom Effects
* Effects can stack
* Fast and light-weight
* Allows rapid development
* And much more ...

(For a full list and documentation, see the wiki or docs.)

## Scripting

See: https://projectdvn.com/Docs/scripting-language

#### Script-Agnostic Architecture

DVN does not rely on a specific scripting language.

The built-in .vns script format is only a parser included with the engine, not a core requirement.
DVN itself only needs scene graph data (SceneEntry objects), meaning:

You can replace the scripting language entirely.

You can load scenes from JSON, YAML, Lua, Ink, or any custom format.

You can generate scenes procedurally at runtime.

Tools can build scenes directly without parsing text.

Modders can add new scripting formats without modifying the engine.

If your custom parser constructs the scene graph correctly,
DVN will run it exactly like native scripts.

This makes DVN fundamentally different from interpreter-driven VN engines:
DVN is a data-driven runtime, not a language-bound interpreter.

#### DVN Scripting Is This Simple

Example:

```ini
[act-8-rooftop-conversation]
c=Yume,Uni_Smile
Yume=...Yume.
=Have you noticed how the flowers bloom in April?
narrator=250,250
What does she mean? We're not in April.
Yume=I think flowers and humans are alike.
=We also bloom best when we're being cared for.
```

Branching example

```ini
[choice-scene]
What should I do?
StayWithYume -> Stay with Yume.
LeaveYume -> Leave her behind.

[StayWithYume]
I decide to stay with her.

[LeaveYume]
I can't stay here any longer.
```

## Who It's For

Project DVN is perfect for writers and developers of all experience levels. Whether you're creating a personal passion project or a commercial release, Project DVN empowers you to build engaging stories across all genres imaginable.

## Why Project DVN?

Project DVN combines ease of use with powerful features, making it the ideal choice for creating visual novels. With its innovation, expansive capabilities and flexibility, Project DVN helps you focus on storytelling, while providing all the support you need to deliver a polished, professional product.

## Unleash Your Creativity

With Project DVN, the power to create unforgettable narrative experiences is in your hands. Start your journey and bring your stories to life today!

To create your first visual novel see: https://projectdvn.com/docs/getting-started

---

### Preview

![DVN Preview](https://tcwtnc.com/images/menu.png "DVN Preview")

![DVN Preview](https://tcwtnc.com/images/rooftop_scene.png "DVN Preview")

![DVN Preview](https://tcwtnc.com/images/classroom_scene.png "DVN Preview")

![DVN Preview](https://tcwtnc.com/images/bench.png "DVN Preview")

---

### Building

See:

https://projectdvn.com/Docs/getting-started#installing-dvn

\+

https://projectdvn.com/Docs/getting-started#building

### Events

https://projectdvn.com/Docs/events

### Contributing

If you wish to contribute just go ahead and do a pull-request or create an issue if you wish to discuss the design of a feature further.

### Visual Novels Using Project DVN

* [The Classroom Where Tomorrow Never Comes](https://tcwtnc.com/)

---

![Project DVN](https://projectdvn.com/images/mascot.png "DVN")