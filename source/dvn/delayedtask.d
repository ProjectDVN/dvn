/**
* Copyright (c) 2025 Project DVN
*/
module dvn.delayedtask;

import std.array : array;

import dvn.external;

private ulong _delayedTaskId;
private DelayedTask[ulong] _tasks;

public class DelayedTask
{
    private:
    ulong _id;
    uint _lastMS;
    uint _delay;
    bool delegate(DelayedTask) _task;
    bool _executed;
    bool _repeat;

    public:
    this(uint delay, bool delegate(DelayedTask) task, bool repeat = false)
    {
        _delay = delay;
        _delayedTaskId++;
        _id = _delayedTaskId;
        _lastMS = 0;
        _task = task;
        _executed = false;
        _repeat = repeat;
    }

    @property bool executed() { return _executed; }

    void handle(uint ms)
    {
        if (_lastMS == 0)
        {
            _lastMS = ms;
        }
        else if ((ms - _lastMS) > _delay)
        {
            _executed = true;

            if (_repeat)
            {
                _lastMS = 0;
            }
            else
            {
                _tasks.remove(_id);
            }

            auto result = _task(this);

            if (result)
            {
                _tasks.remove(_id);
            }
        }
    }
}

ulong runDelayedTask(uint delay, void delegate() task, bool repeat = false)
{
    return runDelayedTask(delay, (d) { task(); return false; }, repeat);
}

ulong runDelayedTask(uint delay, bool delegate(DelayedTask) task, bool repeat = false)
{
    auto delayedTask = new DelayedTask(delay, task, repeat);

    _tasks[delayedTask._id] = delayedTask;

    return delayedTask._id;
}

void removeDelayedTask(ulong id)
{
    if (!_tasks)
    {
        return;
    }

    _tasks.remove(id);
}

void handleDelayedTasks()
{
    if (!_tasks)
    {
        return;
    }

    if (!_tasks.length)
    {
        return;
    }

    auto ms = EXT_GetTicks();

    auto tasks = _tasks.values.array;

    foreach (task; tasks)
    {
        task.handle(ms);
    }
}