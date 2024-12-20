module dvn.sheetcollection;

import dvn.window;
import dvn.external;

public final class SheetCollection
{
  private:
  Window _window;
  EXT_Sheet[string] _sheets;

  alias SHEET_ENTRY_DELEGATE = EXT_SheetRender* delegate();
  SHEET_ENTRY_DELEGATE[string] _sheetEntries;

  public:
  final:
  this(Window window)
  {
    _window = window;
  }

  EXT_Sheet getSheet(string name)
  {
    return _sheets.get(name, EXT_Sheet.init);
  }

  void addSheet(string name, string path, IntVector columnSize, int columnCount)
  {
    auto sheet = EXT_CREATE_SHEET(_window.nativeScreen, path);

    _sheets[name] = EXT_Sheet(sheet, columnSize, columnCount);
  }

  void addSheetEntry(string name, string sheetName, int row, int col)
  {
    SHEET_ENTRY_DELEGATE create = ()
    {
      EXT_SheetRender* e;
      getSheetEntry(sheetName,row,col,e);

      return e;
    };

    _sheetEntries[name] = create;
  }

  bool getSheetEntry(string entryName, out EXT_SheetRender* sheetRender)
  {
    sheetRender = null;

    if (!_sheetEntries) return false;

    auto sheetEntryCreator = _sheetEntries.get(entryName, null);

    if (!sheetEntryCreator) return false;

    sheetRender = sheetEntryCreator();

    return sheetRender !is null && sheetRender.entry !is null && sheetRender.texture !is null;
  }

  bool getSheetEntry(string sheetName, int row, int col, out EXT_SheetRender* sheetRender)
  {
    sheetRender = null;

    auto sheet = _sheets.get(sheetName, EXT_Sheet.init);

    if (!sheet.sheet)
    {
      return false;
    }

    auto extEntry = EXT_CREATE_SHEET_ENTRY(sheet.sheet, FloatVector(0f,0f), sheet.columnSize, row, sheet.columnCount);

    auto entry = new EXT_SheetEntry(extEntry.rect, extEntry.textureRect);

    if (col > 0)
    {
      entry.textureRect.x = col * entry.textureRect.w;
    }

    sheetRender = new EXT_SheetRender;
    sheetRender.size = sheet.columnSize;
    sheetRender.entry = entry;
    sheetRender.texture = sheet.sheet;

    return true;
  }
}
