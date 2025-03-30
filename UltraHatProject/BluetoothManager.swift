import CoreBluetooth
import AVFoundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var espPeripheral: CBPeripheral?
    var distanceCharacteristic: CBCharacteristic?

    @Published var isBluetoothOn = false
    @Published var isConnected = false
    @Published var distance: String = "N/A"

    let textToSpeech = AVSpeechSynthesizer()

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Check Bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.isBluetoothOn = (central.state == .poweredOn)
        }
    }

    // Scan for ESP32 device
    func startScanning() {
        guard isBluetoothOn else { return }
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    // Found a device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "ESP32_Ultrasonic" {  // Match ESP32 name
            espPeripheral = peripheral
            espPeripheral?.delegate = self
            centralManager?.stopScan()
            centralManager?.connect(peripheral, options: nil)
        }
    }

    // Connected to ESP32
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        peripheral.discoverServices(nil)
        
        let utterance = AVSpeechUtterance(string: "Device connected")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        self.textToSpeech.speak(utterance)
    }

    // Disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.distance = "N/A"
            let utterance = AVSpeechUtterance(string: "Device Disconnected")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            self.textToSpeech.speak(utterance)
        }
    }

    // Found services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    // Found characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                distanceCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    // Received distance data
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value,
              let distanceStr = String(data: data, encoding: .utf8) else { return }

        DispatchQueue.main.async {
            self.distance = distanceStr

            // Convert to float and check distance
            if let distanceValue = Float(distanceStr), distanceValue < 200 {
                self.alertUser()
            }
        }
    }

    // Speak alert
    private func alertUser() {
        let utterance = AVSpeechUtterance(string: "Object Nearby")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        textToSpeech.speak(utterance)
    }
}
