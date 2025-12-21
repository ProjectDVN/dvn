module dvn.versions;

version (DVN_RELEASE)
{
    static const bool isDVNRelease = true;
}
else
{
    static const bool isDVNRelease = false;
}