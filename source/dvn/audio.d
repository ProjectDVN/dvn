/**
* Copyright (c) 2025 Project DVN
*/
module dvn.audio;

import dvn.external;
import dvn.gamesettings;

import std.algorithm : clamp;
import std.math : abs;

/// 
public final class AudioManager
{
    private:
    int  _fadeFrom;
    int  _fadeTo;
    int  _volume;
    int  _fadeStepDelay;
    bool _isFadeIn;
    bool _handleFade;
    int  _lastTicks;
    int  _fadeAmount;

    public:
    final:
/// 
    void beginFade(int from, int to, int fadeStepDelay = 180, int desiredSteps = 24)
    {
        if (_handleFade) return;
        
        _fadeFrom = clamp(from, 0, 100);
        _fadeTo   = clamp(to,   0, 100);

        _fadeStepDelay = fadeStepDelay;
        _isFadeIn      = _fadeFrom < _fadeTo;
        _volume        = _fadeFrom;

        int diff = abs(_fadeTo - _fadeFrom);
        if (diff == 0)
        {
            _handleFade = false;
            EXT_ControlSoundVolume(_fadeTo);
            return;
        }

        _fadeAmount = diff / desiredSteps;
        if (_fadeAmount <= 0)
            _fadeAmount = 1;

        EXT_ControlSoundVolume(_volume);

        _lastTicks  = 0;
        _handleFade = true;
    }

    package(dvn):
    void stopFade(bool setVolume = true)
    {
        _handleFade = false;
        if (setVolume) EXT_ControlSoundVolume(getGlobalSettings().volume);
    }

    void handleFade(int ticks)
    {
        if (!_handleFade)
            return;

        if ((ticks - _lastTicks) < _fadeStepDelay)
            return;

        _lastTicks = ticks;

        if (_isFadeIn)
        {
            _volume += _fadeAmount;

            if (_volume >= _fadeTo)
            {
                _volume     = _fadeTo;
                _handleFade = false;
            }
        }
        else
        {
            _volume -= _fadeAmount;

            if (_volume <= _fadeTo)
            {
                _volume     = _fadeTo;
                _handleFade = false;
            }
        }

        EXT_ControlSoundVolume(_volume);
    }
}
