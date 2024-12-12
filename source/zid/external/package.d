module zid.external;

public
{
  import zid.external.core;

  version (ZID_SDL)
  {
    import zid.external.sdl;
  }
  else static assert(0, "zid only supports SDL for now.");
}
