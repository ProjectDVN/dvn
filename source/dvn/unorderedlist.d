module dvn.unorderedlist;

public struct UnorderedList(T)
{
  private:
  T[] items;
  size_t index;
  size_t count;

  public:
  this(size_t maxQueueSize)
  {
    items = new T[maxQueueSize];
    index = 0;
  }

  @property
  {
    bool has() { return count > 0; }

    size_t length() { return index; }

    size_t capacity() { return items.length; }
  }

  void add(T item)
  {
    if (index >= items.length) return;

    items[index] = item;

    index++;
    count++;
    if (index > items.length)
    {
        index = 0;
    }
  }

  T pop()
  {
    if (count == 0) throw new Exception("no items");

    index--;
    auto item = items[index];
    count--;

    if (index < 0) index = 0;

    return item;
  }
}
