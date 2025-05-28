//
//  ContentView.swift
//  CyberLeafX
//
//  Created by Hg Q. on 20/4/25.
//

import SwiftUI
import Shared

struct ContentView: View {
    let client = NIOClient()

        @State private var inputText: String = ""

        var body: some View {
            VStack {
                ScrollView {
                    Text(client.receivedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                HStack {
                    TextField("Message", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send") {
                        client.send(inputText)
                        inputText = ""
                    }
                }
                .padding()
            }
            .padding()
            .onAppear {
                client.connect(host: "127.0.0.1", port: 9999) // Your server address
            }
            .onDisappear {
                client.close()
            }
        }
}

#Preview {
    ContentView()
}
