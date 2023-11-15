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
    @State var status = "Not started…"
    @State var buttonsDisabled = false
    
    var body: some View {
        VStack {
            Text("Instruments’ “Points of Interest” experiment")
            Text(status)
            Button("Test Async-Await 100 Times") {
                Task {
                    status = "Starting"
                    buttonsDisabled = true
                    for _ in 0 ..< 100 {
                        try await experimentAsyncAwait()
                        status = "Finished \(run) … still running"
                        try await Task.sleep(for: .milliseconds(500))
                    }
                    status = "All done"
                    buttonsDisabled = false
                }
            }
            .disabled(buttonsDisabled)
            
            Button("Test GCD 100 Times") {
                status = "Starting"
                buttonsDisabled = true
                experimentRepeatGCD(times: 100) { index in
                    Task { @MainActor in
                        status = "Finished \(run) … still running"
                    }
                } completion: {
                    Task { @MainActor in
                        status = "All done"
                        buttonsDisabled = false
                    }
                }
            }
            .disabled(buttonsDisabled)
        }
        .padding()
    }

    func experimentAsyncAwait() async throws {
        run += 1

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<4 {
                group.addTask {
                    let id = OSSignpostID(log: poi)
                    os_signpost(.begin, log: poi, name: #function, signpostID: id, "%d: %d", run, index)
                    defer { os_signpost(.end, log: poi, name: #function, signpostID: id) }
                    
                    try await Task.sleep(for: .seconds(1))
                }
            }
            
            try await group.waitForAll()
        }
    }

    func experimentRepeatGCD(
        times: Int,
        index: Int = 0,
        update: @escaping (Int) -> Void,
        completion: @escaping () -> Void
    ) {
        if index >= times { return }
        
        experimentGCD {
            update(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                experimentRepeatGCD(times: times, index: index + 1, update: update, completion: completion)
            }
        }
    }
    
    func experimentGCD(completion: @escaping () -> Void) {
        run += 1

        let queue = DispatchQueue.global()
        let group = DispatchGroup()

        for index in 0..<4 {
            queue.async(group: group) {
                let id = OSSignpostID(log: poi)
                os_signpost(.begin, log: poi, name: #function, signpostID: id, "%d: %d", run, index)
                defer { os_signpost(.end, log: poi, name: #function, signpostID: id) }
                
                spin(for: 1)
            }
        }
        
        group.notify(queue: .main, execute: completion)
    }

    func spin(for interval: TimeInterval) {
        let start = CACurrentMediaTime()
        while CACurrentMediaTime() - start < interval { }
    }
}

#Preview {
    ContentView()
}
