module dvn.network.networkpacket;

public class NetworkPacket
{
    private:
    ubyte[] _buffer;
    size_t _offset;
    int _packetId;
    int _packetVirtualSize;

    public:
    final:
    this(NetworkPacket packet)
    {
        _buffer = packet._buffer ? packet._buffer.dup : [];
        _offset = 0;
        _packetId = packet._packetId;
        _packetVirtualSize = packet._packetVirtualSize;
    }
    
    this(ubyte[] buffer)
    {
        _buffer = buffer ? buffer : [];
        _offset = 0;

        if (buffer && buffer.length >= 8)
        {
            _packetId = read!int;
            _packetVirtualSize = read!int;
        }
    }

    this(int id, int size)
    {
        _packetId = id;
        _packetVirtualSize = size + 4 + 4;

        _buffer = new ubyte[4 + 4 + size];
        _offset = 0;

        write!int(id);
        write!int(_packetVirtualSize);
    }

    @property
    {
        int packetId()
        {
            return _packetId;
        }

        int packetVirtualSize()
        {
            return _packetVirtualSize;
        }

        int packetPhysicalSize()
        {
            return _buffer ? cast(int)_buffer.length : 0;
        }

        size_t offset() { return _offset; }

        void offset(size_t newOffset)
        {
            _offset = newOffset;
        }
    }

    void writeString(dstring value)
    {
        auto stringBuffer = cast(ubyte[])value;

        writeBuffer(stringBuffer);
    }

    void write(T)(inout(T) value)
    {
        static if (is(T == float) || is(T == double) || is(T == real))
        {
            (*cast(T*)(_buffer.ptr + _offset)) = value;
        }
        else
        {
            (*cast(T*)(_buffer.ptr + _offset)) = value;
        }
        _offset += T.sizeof;
    }

    void writeStringList(dstring[] list)
    {
        write!int(cast(int)list.length);
        foreach (s; list)
        {
            writeString(s);
        }
    }

    void writeBuffer(ubyte[] value)
    {
        write!int(cast(int)value.length);

        foreach (v; value)
        {
            write!ubyte(v);
        }
    }

    T read(T)()
    {
        auto value = (*cast(T*)(_buffer.ptr + _offset));

        _offset += T.sizeof;

        static if (is(T == float) || is(T == double) || is(T == real))
        {
            return value;
        }
        else
        {
            return value;
        }
    }

    dstring readString()
    {
        auto str = cast(dstring)readBuffer();

        return (str is null || str.length == 0) ? "" : str;
    }

    dstring[] readStringList()
    {
        auto length = read!int;

        if (length == 0)
        {
            return [];
        }

        dstring[] list = new dstring[length];

        foreach (i; 0 .. length)
        {
            list[i] = readString();
        }

        return list;
    }

    ubyte[] readBuffer()
    {
        auto length = read!int;

        ubyte[] buff = new ubyte[length];
        
        foreach (i; 0 .. length)
        {
            buff[i] = read!ubyte;
        }

        return buff;
    }

    ubyte[] finalizePacket()
    {
        return _buffer ? _buffer.dup : null;
    }
}