import SwiftUI

struct ContentView: View {
    @StateObject var bluetoothManager = BluetoothManager()

    var body: some View {
        VStack(spacing: 20) {
            Text(bluetoothManager.isBluetoothOn ? "" : "Turn on Bluetooth")
                .font(.title)
                .foregroundColor(bluetoothManager.isBluetoothOn ? .green : .red)

            if bluetoothManager.isConnected {
                Text("Connected to ESP32")
                    .font(.headline)
                    .foregroundColor(.green)
                if let distanceValue = Float(bluetoothManager.distance), distanceValue < 200 {
                    Text("Object Nearby")
                        .font(.largeTitle)
                        .bold()
                
                }
                else{
                    Text("All clear")
                        .font(.largeTitle)
                        .bold()
                }
            } else {
                Button(action: {
                    bluetoothManager.startScanning()
                }) {
                    Text("Connect to ESP32")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}
