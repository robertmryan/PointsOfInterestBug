//
//  ContentView.swift
//  PointsOfInterestBug
//
//  Created by Robert Ryan on 9/26/23.
//

import SwiftUI
import os.signpost

let poi = OSSignposter(subsystem: "test", category: .pointsOfInterest)

struct ContentView: View {
    @State var status = "Not started…"
    @State var buttonsDisabled = false
    let iterations = 200
    @State var experiment = Experiment()
    
    func sample(_ name: StaticString) async throws {
        let id = poi.makeSignpostID()
        let state = poi.beginInterval(name, id: id)
        try await Task.sleep(for: .seconds(1))
        poi.endInterval(name, state)
    }
    
    var body: some View {
        VStack {
            Text("Instruments’ “Points of Interest” experiment")
            Text(status)
            
            Button("Unsafe – \(iterations) Times") {
                Task {
                    poi.emitEvent("Async-Await")
                    
                    status = "Starting"
                    buttonsDisabled = true
                    
                    for iteration in 0 ..< iterations {
                        try await experiment.fourConcurrentTasksUnsafe(for: iteration)
                        status = "Finished \(iteration) … still running"
                        try await Task.sleep(for: .seconds(0.25))
                    }
                    
                    status = "All done"
                    buttonsDisabled = false
                }
            }
            .disabled(buttonsDisabled)

            Button("Safe – \(iterations) Times") {
                Task {
                    poi.emitEvent("Async-Await")
                    
                    status = "Starting"
                    buttonsDisabled = true
                    
                    for iteration in 0 ..< iterations {
                        try await experiment.fourConcurrentTasksSafe(for: iteration)
                        status = "Finished \(iteration) … still running"
                        try await Task.sleep(for: .seconds(0.25))
                    }
                    
                    status = "All done"
                    buttonsDisabled = false
                }
            }
            .disabled(buttonsDisabled)
        }
        .padding()
    }
}

final class Experiment: Sendable {
    nonisolated init() { }
        
    func fourConcurrentTasksUnsafe(for run: Int) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in // [lock] group in
            for index in 0..<4 {
                group.addTask {
                    let id = poi.makeSignpostID()
                    let state = poi.beginInterval(#function, id: id, "\(run): \(index)")

                    try await Task.sleep(for: .seconds(0.25))
                    
                    poi.endInterval(#function, state)
                }
            }
            
            try await group.waitForAll()
        }
    }

    func fourConcurrentTasksSafe(for run: Int) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let lock = NSLock()

            for index in 0..<4 {
                group.addTask {
                    let state = lock.withLock {
                        let id = poi.makeSignpostID()
                        return poi.beginInterval(#function, id: id, "\(run): \(index)")
                    }

                    try await Task.sleep(for: .seconds(0.25))
                    
                    lock.withLock {
                        poi.endInterval(#function, state)
                    }
                }
            }
            
            try await group.waitForAll()
        }
    }
}

#Preview {
    ContentView()
}

@globalActor
public actor SignpostActor {
    public static let shared = SignpostActor()
}
