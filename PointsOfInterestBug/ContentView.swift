//
//  ContentView.swift
//  PointsOfInterestBug
//
//  Created by Robert Ryan on 9/26/23.
//

import SwiftUI
import os.log

let poi = OSLog(subsystem: "Test", category: .pointsOfInterest)

struct ContentView: View {
    @State var run = 0

    var body: some View {
        VStack {
            Text("Instruments experiment")
            Button("Experiment") {
                experiment()
            }
        }
        .padding()
    }

    func experiment() {
        run += 1

        let queue = DispatchQueue.global()

        for i in 0..<4 {
            queue.async {
                interval(prefix: "async", run: run, index: i) {
                    spin(for: 1)
                }
            }
        }
    }

    func interval(prefix: StaticString, run: Int, index: Int, block: () -> Void) {
        let id = OSSignpostID(log: poi)
        os_signpost(.begin, log: poi, name: prefix, signpostID: id, "%d: %d", run, index)
        block()
        os_signpost(.end, log: poi, name: prefix, signpostID: id)
    }

    func spin(for interval: TimeInterval) {
        let start = CACurrentMediaTime()
        while CACurrentMediaTime() - start < interval { }
    }
}

#Preview {
    ContentView()
}
