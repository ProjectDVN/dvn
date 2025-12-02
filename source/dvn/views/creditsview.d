/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.creditsview;

import dvn;
import std.conv : to;
import std.array : join;
import std.file : exists, readText;

public final class CreditsData
{
    public:
    final:
    string music;
    CreditsInfo[] entries;
}

public final class CreditsInfo
{
    public:
    final:
    string title;
    string[] people;
}

public final class CreditsView : View
{
    public:
    final:
    this(Window window)
    {
        super(window);
    }

    protected override void onInitialize(bool useCache)
    {
        EXT_DisableKeyboardState();

        auto window = super.window;
		auto settings = getGlobalSettings();

        Label[][] creditLabels = [];

        if (!exists("data/credits.json"))
        {
            window.fadeToView("MainMenu", getColorByName("black"), false);
            return;
        }

        string text = readText("data/credits.json");
        string[] errorMessages;
        CreditsData creditsData;
        if (!deserializeJsonSafe!(CreditsData)(text, creditsData, errorMessages))
        {
            throw new Exception(errorMessages[0]);
        }

        auto music = getMusicPath(creditsData.music);

        if (music && music.length)
        {
            EXT_PlayMusic(music);
        }

        auto creditsInfo = creditsData.entries;

        foreach (creditInfo; creditsInfo)
        {
            auto creditTitleLabel = new Label(window);
            addComponent(creditTitleLabel);
            creditTitleLabel.fontName = settings.defaultFont;
            creditTitleLabel.fontSize = 18;
            creditTitleLabel.color = "fff".getColorByHex;
            creditTitleLabel.text = creditInfo.title.to!dstring;
            creditTitleLabel.shadow = true;
            creditTitleLabel.isLink = false;
            creditTitleLabel.position = IntVector(
                ((window.width / 2) - (creditTitleLabel.width / 2)),
                ((window.height / 2) - (creditTitleLabel.height / 2)) - 18
            );
            creditTitleLabel.updateRect();
            creditTitleLabel.hide();

            auto creditPeopleLabel = new Label(window);
            addComponent(creditPeopleLabel);
            creditPeopleLabel.fontName = settings.defaultFont;
            creditPeopleLabel.fontSize = 18;
            creditPeopleLabel.color = "fff".getColorByHex;
            creditPeopleLabel.text = (creditInfo.people.join(", ")).to!dstring;
            creditPeopleLabel.shadow = true;
            creditPeopleLabel.isLink = false;
            creditPeopleLabel.position = IntVector(
                ((window.width / 2) - (creditPeopleLabel.width / 2)),
                ((window.height / 2) - (creditPeopleLabel.height / 2)) + 18
            );
            creditPeopleLabel.updateRect();
            creditPeopleLabel.hide();

            creditLabels ~= [creditTitleLabel, creditPeopleLabel];
        }

        int index = 0;

        Label lastCreditTitle;
        Label lastCreditPeople;

        bool finished = false;

        runDelayedTask(4000, (d) {
            if (finished)
            {
                window.fadeToView("MainMenu", getColorByName("black"), false);
                return true;
            }
            
            if (lastCreditTitle)
            {
                lastCreditTitle.hide();
            }

            if (lastCreditPeople)
            {
                lastCreditPeople.hide();
            }

            auto creditTitle = creditLabels[index][0];
            lastCreditTitle = creditTitle;
            auto creditPeople = creditLabels[index][1];
            lastCreditPeople = creditPeople;

            creditTitle.show();
            creditPeople.show();

            index++;

            finished = index >= creditLabels.length;

            return false;
        }, true);
    }
}