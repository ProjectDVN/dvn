module dvn.network.networksocket;

import std.socket;
import std.concurrency;
import std.conv : to;
import std.algorithm : map;
import std.array : array;
import core.thread : Thread, dur;
import std.datetime : Clock;

import dvn.network.networkpacket;

public final class NetworkSocket
{
    private:
    Socket _socket;
    bool _disconnected;
    void delegate(NetworkPacket) _packetHandler;
    void delegate(Throwable) _errorHandler;

    public:
    final:
    this(void delegate(Throwable) errorHandler, void delegate(NetworkPacket) packetHandler = null)
    {
        _socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);

        _packetHandler = packetHandler;
        _errorHandler = errorHandler;
    }

    @property
    {
        Socket socket() { return _socket; }

        bool isDisconnected() { return _disconnected; }
    }

    void connect(string ip, ushort port)
    {
        _socket.connect(new InternetAddress(ip, port));
    }

    void close()
    {
        _socket.close();
    }

    void send(NetworkPacket packet, bool allowViewChange = true)
    {
        synchronized
        {
            if (_disconnected)
            {
                return;
            }

            auto buffer = packet.finalizePacket;
    
            ptrdiff_t sent = _socket.send(buffer, SocketFlags.NONE);

            if (sent == -1 || sent == 0)
            {
                import std.conv : to;

                throw new Exception("Disconnected [" ~ sent.to!string ~ "]");
            }
        }
    }

    private void copyBuffer(ubyte[] src, ubyte[] dest, int destOffset, ptrdiff_t destLength)
    {
        auto sourceIndex = 0;

        foreach (i; cast(ptrdiff_t)destOffset .. cast(ptrdiff_t)destOffset + cast(ptrdiff_t)destLength)
        {
            dest[i] = src[sourceIndex];
            sourceIndex++;
        }
    }

    private ubyte[] receive()
    {
        synchronized
        {
            if (_disconnected)
            {
                throw new Exception("Disconnected ...");
            }
        }

       ubyte[] header = new ubyte[8];

       auto totalReceived = 0;
       while (totalReceived < header.length)
       {
            auto tempBufferSize = header.length - totalReceived;
            auto tempBuffer = new ubyte[tempBufferSize];
            
            auto recv = _socket.receive(tempBuffer, SocketFlags.NONE);

            if (!_socket.isAlive)
            {
                throw new Exception("Socket is not alive. [header]");
            }

            if (recv == 0)
            {
                throw new Exception("Failed to receive the header packet :: " ~ _socket.getErrorText);
            }

            copyBuffer(tempBuffer, header, totalReceived, recv);

            totalReceived += recv;
       }

       auto headerPacket = new NetworkPacket(header);

       if (!headerPacket.packetId || !headerPacket.packetVirtualSize || headerPacket.packetVirtualSize == -1)
       {
        throw new Exception("Disconnection - dead packet");
       }

       auto bodyBuffer = new ubyte[(cast(size_t)headerPacket.packetVirtualSize) - 8];

       totalReceived = 0;
       while (totalReceived < bodyBuffer.length)
       {
            auto tempBufferSize = bodyBuffer.length - totalReceived;
            auto tempBuffer = new ubyte[tempBufferSize];

            auto recv = _socket.receive(tempBuffer, SocketFlags.NONE);
            
            if (!_socket.isAlive)
            {
                throw new Exception("Socket is not alive. [body]");
            }

            if (recv <= 0)
            {
                throw new Exception("Failed to receive the body packet :: " ~ _socket.getErrorText);
            }

            copyBuffer(tempBuffer, bodyBuffer, totalReceived, recv);

            totalReceived += recv;
       }
       
       return header ~ bodyBuffer;
    }
}

private void handleSocket(string ip, ushort port, shared NetworkSocket s)
{
    if (!s) return;
    auto socket = cast(NetworkSocket)s;

    try
    {
        socket.connect(ip, port);

        while (true)
        {
            auto packet = new NetworkPacket(socket.receive());

            if (socket._packetHandler) socket._packetHandler(packet);
        }
    }
    catch (Throwable e)
    {
        synchronized
        {
            socket._disconnected = true;
        }

        if (socket._errorHandler) socket._errorHandler(e);
    }
}

NetworkSocket handle(string ip, ushort port, void delegate(Throwable) errorHandler, void delegate(NetworkPacket) packetHandler = null)
{
    auto socket = new NetworkSocket(errorHandler, packetHandler);
    
    spawn(&handleSocket, ip, port, cast(shared)socket);

    return socket;
}