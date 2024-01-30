//
//  SocketServer.swift
//  broadcast
//
//  Created by Nikola Shabanov on 30.01.24.
//

import CocoaAsyncSocket

class SocketServer: NSObject, GCDAsyncSocketDelegate {
    var socket: GCDAsyncSocket?
    var connectedSockets: [GCDAsyncSocket] = []

    override init() {
        super.init()
        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }

    func startServer(onPort port: UInt16) {
        do {
            try socket?.accept(onPort: port)
            print("Server started on port \(port)")
        } catch let error {
            print("Error starting server: \(error)")
        }
    }

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Accepted new socket from \(newSocket.connectedHost ?? ""):\(newSocket.connectedPort)")
        connectedSockets.append(newSocket)

        // Start reading data from the socket
        newSocket.readData(withTimeout: -1, tag: 0)
    }
    
    func sendDataToAllClients(_ data: Data) {
            for clientSocket in connectedSockets {
                clientSocket.write(data, withTimeout: -1, tag: 0)
            }
        }
}
