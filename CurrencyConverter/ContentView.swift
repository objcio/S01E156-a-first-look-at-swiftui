//
//  ContentView.swift
//  CurrencyConverter
//
//  Created by Chris Eidhof on 13.06.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import SwiftUI
import TinyNetworking

struct FixerData: Codable {
    var rates: [String:Double]
}

let latest = Endpoint<FixerData>(json: .get, url: URL(string: "http://data.fixer.io/api/latest?access_key=dd7e92eca8f55f5d102f6802921ffa72&format=1")!)

import Combine

final class Resource<A>: BindableObject {
    let didChange = PassthroughSubject<A?, Never>()
    let endpoint: Endpoint<A>
    var value: A? {
        didSet {
            sleep(2)
            DispatchQueue.main.async {
                self.didChange.send(self.value)
            }
        }
    }
    init(endpoint: Endpoint<A>) {
        self.endpoint = endpoint
        reload()
    }
    func reload() {
        URLSession.shared.load(endpoint) { result in
            self.value = try? result.get()
        }
    }
}

struct Converter: View {
    let rates: [String: Double]
    @State var text: String = "100"
    @State var selection: String = "USD"
    var rate: Double {
        rates[selection]!
    }
    let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = ""
        return f
    }()
    var parsedInput: Double? {
        Double(text)
    }
    var output: String {
        parsedInput.flatMap { formatter.string(from: NSNumber(value: $0 * self.rate)) } ?? "parse error"
    }
    var body: some View {
        VStack {
            HStack {
                TextField($text).frame(width: 100)
                Text("EUR")
                Text("=")
                Text(output)
                Text(selection)
            }
            Picker(selection: $selection, label: Text("")) {
                ForEach(self.rates.keys.sorted().identified(by: \.self)) { key in
                    Text(key)
                }
            }
        }
    }
}

struct ProgressIndicator: NSViewRepresentable {
    func makeNSView(context: NSViewRepresentableContext<ProgressIndicator>) -> NSProgressIndicator {
        let progressIndicator = NSProgressIndicator()
        progressIndicator.startAnimation(nil)
        progressIndicator.style = .spinning
        return progressIndicator
    }
    
    func updateNSView(_ nsView: NSProgressIndicator, context: NSViewRepresentableContext<ProgressIndicator>) {
    }
}

struct ContentView : View {
    @ObjectBinding var resource = Resource(endpoint: latest)
    var body: some View {
        Group {
            if resource.value == nil {
                VStack {
                    Text("Loading...")
                    ProgressIndicator()
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Converter(rates: resource.value!.rates)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
