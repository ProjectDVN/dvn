module dvn.gallery;

string[] getGalleryPaged(int page)
{
    import std.file : dirEntries, SpanMode;
    import std.algorithm : filter, endsWith;

    string[] s = [];

    int skip = page * 6;
    int take = 6;

    string[] images = [];

    auto imageFiles = dirEntries("data/game/gallery", SpanMode.shallow).filter!(f => f.name.endsWith(".png"));
    foreach (imageFile; imageFiles)
    {
        images ~= imageFile.name;
    }

    foreach (i; skip .. (skip + take))
    {
        if (i >= images.length) continue;
            
        auto image = images[i];
        s ~= image;
    }

    return s;
}