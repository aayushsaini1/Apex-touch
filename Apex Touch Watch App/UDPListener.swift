import Combine
import Foundation
import Network

class UDPListener: ObservableObject {
    private var listener: NWListener?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "UDPListenerQueue")

    @Published var isListening = false
    @Published var lastError: String?

    var onDataReceived: ((Data) -> Void)?

    func start(port: UInt16) {
        do {
            let nwPort = NWEndpoint.Port(rawValue: port)!
            let parameters = NWParameters.udp

            listener = try NWListener(using: parameters, on: nwPort)

            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isListening = true
                        self?.lastError = nil
                    case .failed(let error):
                        self?.isListening = false
                        self?.lastError = error.localizedDescription
                    case .cancelled:
                        self?.isListening = false
                    default:
                        break
                    }
                }
            }

            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.setupConnection(newConnection)
            }

            listener?.start(queue: queue)

        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func stop() {
        listener?.cancel()
        connection?.cancel()
        isListening = false
    }

    private func setupConnection(_ connection: NWConnection) {
        print("UDP: New connection from \(connection.endpoint)")
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            print("UDP: Connection state: \(state)")
            switch state {
            case .ready:
                self?.receiveMessage()
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func receiveMessage() {
        // Use receive instead of receiveMessage to handle fragmented UDP packets up to 64KB
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65535) { [weak self] (content, context, isComplete, error) in
            if let data = content {
                self?.onDataReceived?(data)
            }
            if error == nil {
                self?.receiveMessage()
            }
        }
    }
}
