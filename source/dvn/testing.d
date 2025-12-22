module dvn.testing;

bool willThrow(void delegate() f)
{
    try
    {
        f();
        return false;
    }
    catch (Exception e)
    {
        return true;
    }
}

bool willThrow(void function() f)
{
    try
    {
        f();
        return false;
    }
    catch (Exception e)
    {
        return true;
    }
}