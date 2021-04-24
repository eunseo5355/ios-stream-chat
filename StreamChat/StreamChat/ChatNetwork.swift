import Foundation

final class ChatNetwork: NSObject {
    private var inputStream: InputStream!
    private var outputStream: OutputStream!
    private let username = "3pro😎"
    private let maxMessageLength = 300
    
    func setupNetwork() {
        let serverAddress = "stream-ios.yagom-academy.kr" as CFString
        let serverPort: UInt32 = 7748
        
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, serverAddress, serverPort, &readStream, &writeStream)
        
        inputStream = readStream?.takeRetainedValue()
        outputStream = writeStream?.takeRetainedValue()
        
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        
        inputStream.delegate = self
        
        inputStream.open()
        outputStream.open()
    }
    
    func connectChat() {
        let joinMessage = "USR_NAME::\(username)".data(using: .utf8)!
    
        joinMessage.withUnsafeBytes { (unsafeRawBufferPointer) in
            guard let message = unsafeRawBufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                print("채팅 연결 실패")
                return
            }
            
            // Writes the contents of a provided data buffer to the receiver.
            let result = outputStream.write(message, maxLength: joinMessage.count)
            if result > 0 {
                print("연결 메시지 전송 성공")
            } else {
                print("연결 메시지 전송 실패")
            }
        }
    }
}

extension ChatNetwork: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            readMessage(stream: aStream as! InputStream)
        default:
            print("다른 스트림 이벤트 발생")
        }
    }
    
    private func readMessage(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxMessageLength)
        let readBytes = inputStream.read(buffer, maxLength: maxMessageLength)

        guard let messages = String(bytesNoCopy: buffer, length: readBytes, encoding: .utf8, freeWhenDone: true) else {
            return
        }
        
        print(messages)
    }
}
