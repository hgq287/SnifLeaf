//
//  AnomaliesInteractor.swift
//  SnifLeaf-macOS
//

import Foundation
import CoreML
import Combine
import SnifLeafDomain
import SnifLeafApplication

public final class AnomaliesInteractor: ObservableObject {
    private let fetchPaginatedLogs: FetchPaginatedLogsUseCase

    @Published public var anomalies: [SnifLeafDomain.LogEntry] = []
    @Published public var isSystemHealthy: Bool = true

    private var aiModel: EndpointAnomalyDetector?

    public init(fetchPaginatedLogs: FetchPaginatedLogsUseCase) {
        self.fetchPaginatedLogs = fetchPaginatedLogs
        setupModel()
        Task {
            let (entries, _) = try await fetchPaginatedLogs.loadPage(offset: 0, limit: 500, searchText: "")
            analyzeEntries(entries)
        }
    }

    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            aiModel = try EndpointAnomalyDetector(configuration: config)
        } catch {
            print("AI Model failed to load: \(error)")
        }
    }

    func analyzeEntries(_ entries: [SnifLeafDomain.LogEntry]) {
        guard let model = aiModel else { return }

        var detectedAnomalies: [SnifLeafDomain.LogEntry] = []

        for entry in entries {
            do {
                let input = EndpointAnomalyDetectorInput(
                    latency: entry.latency,
                    requestSize: Double(entry.requestSize),
                    responseSize: Double(entry.responseSize)
                )
                let prediction = try model.prediction(input: input)
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
