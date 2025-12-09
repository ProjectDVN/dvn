/**
* Copyright (c) 2025 Project DVN
*/
module dvn.network.networkpacket;

import std.system : Endian;
import std.bitmanip : bigEndianToNative, nativeToBigEndian, littleEndianToNative, nativeToLittleEndian;
import std.traits : isIntegral, isFloatingPoint;
import std.conv : bitCast;

/// 
public class NetworkPacket
{
    private:
    ubyte[] _buffer;
    size_t _offset;
    int _packetId;
    int _packetVirtualSize;
    Endian _packetEndian;

    public:
    final:
/// 
    this(NetworkPacket packet)
    {
        assert(packet !is null, "NetworkPacket must not be null");

        _buffer = packet._buffer ? packet._buffer.dup : [];
        _offset = 0;
        _packetId = packet._packetId;
        _packetVirtualSize = packet._packetVirtualSize;
        _packetEndian = packet._packetEndian;
    }
    
/// 
    this(ubyte[] buffer, Endian endian = Endian.bigEndian)
    {
        assert(buffer !is null, "NetworkPacket buffer must not be null");

        _packetEndian = endian;

        _buffer = buffer ? buffer : [];
        _offset = 0;

        if (buffer && buffer.length >= 8)
        {
            _packetId = read!int;
            _packetVirtualSize = read!int;
        }
    }

/// 
    this(int id, int size, Endian endian = Endian.bigEndian)
    {
        _packetEndian = endian;
        
        _packetId = id;
        _packetVirtualSize = size + 4 + 4;

        _buffer = new ubyte[4 + 4 + size];
        _offset = 0;

        write!int(id);
        write!int(_packetVirtualSize);
    }

    @property
    {
/// 
        Endian packetEndian() const { return _packetEndian; }
/// 
        void packetEndian(Endian e) { _packetEndian = e; }

/// 
        int packetId()
        {
            return _packetId;
        }

/// 
        int packetVirtualSize()
        {
            return _packetVirtualSize;
        }

/// 
        int packetPhysicalSize()
        {
            return _buffer ? cast(int)_buffer.length : 0;
        }

/// 
        size_t offset() { return _offset; }

/// 
        void offset(size_t newOffset)
        {
            _offset = newOffset;
        }
    }

/// 
    void writeStringUTF32(dstring value)
    {
        auto stringBuffer = cast(ubyte[])value;

        writeBuffer(stringBuffer);
    }

/// 
    void write(T)(T value)
        if (isIntegral!T || isFloatingPoint!T)
    {
        static if (is(T == float))
        {
            int bits = bitCast!int(value);
            write!int(bits);
        }
        else static if (is(T == double))
        {
            long bits = bitCast!long(value);
            write!long(bits);
        }
        else static if (is(T == ubyte))
        {
             (*cast(T*)(_buffer.ptr + _offset)) = value;
            _offset += T.sizeof;
        }
        else static if (isIntegral!T)
        {
            ubyte[T.sizeof] buf;
            final switch (_packetEndian)
            {
                case Endian.bigEndian:
                    buf = nativeToBigEndian(value);
                    break;
                case Endian.littleEndian:
                    buf = nativeToLittleEndian(value);
                    break;
            }

            writeStaticBuffer(buf);
        }
    }

/// 
    void writeStringListUTF32(dstring[] list)
    {
        write!int(cast(int)list.length);
        foreach (s; list)
        {
            writeStringUTF32(s);
        }
    }

/// 
    void writeBuffer(ubyte[] value)
    {
        write!int(cast(int)value.length);

        foreach (v; value)
        {
            write!ubyte(v);
        }
    }

/// 
    void writeStaticBuffer(ubyte[] value)
    {
        foreach (v; value)
        {
            write!ubyte(v);
        }
    }

/// 
    T read(T)()
        if (isIntegral!T || isFloatingPoint!T)
    {
        static if (is(T == float))
        {
            int bits = read!int();

            return bitCast!float(bits);
        }
        else static if (is(T == double))
        {
            long bits = read!long();
            
            return bitCast!double(bits);
        }
        else
        {
            T value;
            ubyte[] slice = _buffer[_offset .. (_offset + T.sizeof)];
            ubyte[T.sizeof] temp;
            temp[] = cast(ubyte[]) slice;

            static if (isIntegral!T)
            {
                final switch (_packetEndian)
                {
                    case Endian.bigEndian:
                        value = bigEndianToNative!(T,T.sizeof)(temp);
                        break;
                    case Endian.littleEndian:
                        value = littleEndianToNative!(T,T.sizeof)(temp);
                        break;
                }
            }

            _offset += T.sizeof;

            return value;
        }
    }

/// 
    dstring readStringUTF32()
    {
        auto str = cast(dstring)readBuffer();

        return (str is null || str.length == 0) ? "" : str;
    }

/// 
    dstring[] readStringListUTF32()
    {
        auto length = read!int;

        if (length == 0)
        {
            return [];
        }

        dstring[] list = new dstring[length];

        foreach (i; 0 .. length)
        {
            list[i] = readStringUTF32();
        }

        return list;
    }

/// 
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

/// 
    ubyte[] readStaticBuffer(int length)
    {
        ubyte[] buff = new ubyte[length];
        
        foreach (i; 0 .. length)
        {
            buff[i] = read!ubyte;
        }

        return buff;
    }

/// 
    ubyte[] finalizePacket()
    {
        return _buffer ? _buffer.dup : null;
    }
}