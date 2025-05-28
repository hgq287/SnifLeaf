//
//  NioClient.swift
//  Shared
//
//  Created by Hg Q. on 28/5/25.
//

import Foundation
import NIO
import NIOExtras

// MARK: - SwiftNIO TCP Client

public final class NIOClient: ObservableObject, ChannelInboundHandler {
    public typealias InboundIn = String

    private var group: EventLoopGroup!
    private var channel: Channel?

    @Published public var receivedText = ""

    public init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    public func connect(host: String, port: Int) {
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.socketOption(.tcp_nodelay), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(ByteToMessageHandler(LineBasedFrameDecoder()))
                    .flatMap {
                        channel.pipeline.addHandler(self)
                    }
                    .flatMap {
                        channel.pipeline.addHandler(self)
                    }
            }

        bootstrap.connect(host: host, port: port).whenComplete { result in
            switch result {
            case .success(let channel):
                print("Connected to \(host):\(port)")
                self.channel = channel
            case .failure(let error):
                print("Failed to connect: \(error)")
            }
        }
    }

    public func send(_ text: String) {
        guard let channel = channel else { return }
        var buffer = channel.allocator.buffer(capacity: text.utf8.count + 2)
        buffer.writeString(text + "\r\n")
        channel.writeAndFlush(NIOAny(buffer), promise: nil)
    }

    public func close() {
        do {
            try channel?.close().wait()
            try group.syncShutdownGracefully()
            print("Connection closed")
        } catch {
            print("Error closing connection: \(error)")
        }
    }

    // MARK: ChannelInboundHandler methods

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        DispatchQueue.main.async {
            self.receivedText += message + "\n"
        }
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("NIO error: \(error)")
        context.close(promise: nil)
    }
}
