//
//  AnomaliesInteractor.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 26/12/25.
//

import Foundation
import CoreML
import Combine
import SnifLeafCore

public final class AnomaliesInteractor: ObservableObject {
    // MARK: - Dependencies
    private let dbManager: GRDBManager
    
    @Published var anomalies: [LogEntry] = []
    @Published var isSystemHealthy: Bool = true
    
    // Auto-generated class from your .mlpackage
    private var aiModel: EndpointAnomalyDetector?

    public init(dbManager: GRDBManager) {
        self.dbManager = dbManager
        setupModel()
        Task {
            let entries = await fetchLogEntriesBatch()
            analyzeEntries(entries)
        }
    }

    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            self.aiModel = try EndpointAnomalyDetector(configuration: config)
        } catch {
            print("AI Model failed to load: \(error)")
        }
    }
    
    private func fetchLogEntriesBatch(limit: Int = 500) async -> [LogEntry] {
        do {
            let entries = await dbManager.fetchLogEntries(limit: limit, offset: 0)
            return entries
        } catch {
            print("Failed to fetch log entries: \(error)")
            return []
        }
    }

    /// Run AI analysis on a batch of entries
    func analyzeEntries(_ entries: [LogEntry]) {
        guard let model = aiModel else { return }
        
        var detectedAnomalies: [LogEntry] = []
        
        for entry in entries {
            do {
                // Mapping input based on your Python training features
                let input = EndpointAnomalyDetectorInput(
                    latency: entry.latency,
                    requestSize: Double(entry.requestSize),
                    responseSize: Double(entry.responseSize)
                )
                
                let prediction = try model.prediction(input: input)
                
                // 1 = Anomaly (based on our RandomForestClassifier update)
                if prediction.is_anomaly == 1 {
                    detectedAnomalies.append(entry)
                }
            } catch {
                continue
            }
        }
        
        DispatchQueue.main.async {
            self.anomalies = detectedAnomalies
            self.isSystemHealthy = detectedAnomalies.isEmpty
        }
    }
}
