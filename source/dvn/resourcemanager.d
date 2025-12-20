module dvn.resourcemanager;

import dvn.ui;
import dvn.resources;
import dvn.delayedtask;
import dvn.events;
import dvn.bundling;
import dvn.external;
import dvn.gamesettings;
import dvn.characters;

public static class ResourceManager
{
    public:
    static:
    void load(Window mainWindow, GameSettings settings)
    {
        void addResources(Resource[string] resources)
        {
            foreach (k,v; resources)
            {
                DvnEvents.getEvents().loadingResource(k,v);

                if (v.randomPath && v.randomPath.length)
                {
                    import std.random : uniform;

                    v.path = v.randomPath[uniform(0,v.randomPath.length)];
                }

                ResourceSize size;
                if (v.size)
                {
                    size = v.size;
                }
                else
                {
                    import std.string : toStringz;

                    auto temp1 = EXT_IMG_Load(v.path.toStringz);
                    auto temp2 = EXT_CreateTextureFromSurface(mainWindow.nativeScreen, temp1);
                    auto originalSize = EXT_QueryTextureSize(temp2);
                    size = new ResourceSize;
                    size.width = originalSize.x;
                    size.height = originalSize.y;

                    EXT_DestroyTexture(temp2);
                    EXT_FreeSurface(temp1);
                }

                mainWindow.addSheet(k, v.path, IntVector(size.width, size.height), v.columns ? v.columns : 1);

                if (v.entries && v.entries.length)
                {
                    foreach (entry; v.entries)
                    {
                        mainWindow.addSheetEntry(entry.name, k, entry.row, entry.col);
                    }
                }
                else
                {
                    mainWindow.addSheetEntry(k, k, 0, 0);
                }

                DvnEvents.getEvents().loadedResource(k,v);
            }
        }

        auto generalResources = loadResources("data/resources/main.json");

        DvnEvents.getEvents().loadingAllResources(generalResources);

        appendResources(generalResources, "data/game/backgrounds.json");
        if (settings.useLegacyCharacters)
        {
            appendResources(generalResources, "data/game/characters.json");
        }
        else
        {
            loadCharacters(generalResources);
        }
        appendResources(generalResources, "data/game/animations.json");

        DvnEvents.getEvents().loadingAllResources(generalResources);

        auto wroteBundle = writeBundleScript();
        readBundleScript();

        auto wroteImageBundle = writeBundleImages(generalResources);
        auto streamedBundle = streamBundleImages((n,b)
        {
            auto resource = new Resource;
            resource.buffer = b;

            DvnEvents.getEvents().loadingResource(n,resource);

            EXT_RWops rw = EXT_RWFromConstMem(b.ptr, cast(int) b.length);
            EXT_Surface temp1 = EXT_IMG_Load_RW(rw, 1);

            auto temp2 = EXT_CreateTextureFromSurface(mainWindow.nativeScreen, temp1);
            auto originalSize = EXT_QueryTextureSize(temp2);

            auto size = new ResourceSize;
            size.width = originalSize.x;
            size.height = originalSize.y;
            resource.size = size;

            mainWindow.addSheetBuffer(n, resource.buffer, IntVector(size.width, size.height), 1);

            mainWindow.addSheetEntry(n, n, 0, 0);

            EXT_DestroyTexture(temp2);
            EXT_FreeSurface(temp1);

            DvnEvents.getEvents().loadedResource(n,resource);
        });

        wroteBundle = wroteBundle || wroteImageBundle;
        if (wroteBundle)
        {
            clearBundling();
        }

        if (!streamedBundle) addResources(generalResources);

        DvnEvents.getEvents().loadedAllResources();
    }

    void clear(Window window, GameSettings settings, void delegate(Window) cleared)
    {
        auto view = window.getCurrentActiveView();

        if (view)
        {
            view.clean();
        }

        window.cleanComponents();

        runDelayedTask(0, {
            window.clearAllSheets();
            window.enableSheets();
            load(window, settings);
            cleared(window);
        });
    }
}