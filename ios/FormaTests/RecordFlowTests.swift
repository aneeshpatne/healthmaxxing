import Testing
@testable import Forma

struct RecordFlowTests {
    @Test func simultaneousMetricsStillAdvanceInOrder() {
        let measurement = ScaleMeasurement(
            weightKg: 73.5,
            heartRate: 72,
            impedanceOhms: 510,
            isFinal: true
        )

        #expect(RecordMetricProgression.nextStage(after: nil, measurement: measurement) == .weight)
        #expect(RecordMetricProgression.nextStage(after: .weight, measurement: measurement) == .impedance)
        #expect(RecordMetricProgression.nextStage(after: .impedance, measurement: measurement) == .heartRate)
        #expect(RecordMetricProgression.nextStage(after: .heartRate, measurement: measurement) == nil)
    }

    @Test func progressionWaitsForTheNextMetric() {
        let weightOnly = ScaleMeasurement(weightKg: 73.5)
        let weightAndImpedance = ScaleMeasurement(weightKg: 73.5, impedanceOhms: 510)

        #expect(RecordMetricProgression.nextStage(after: .weight, measurement: weightOnly) == nil)
        #expect(RecordMetricProgression.nextStage(after: .weight, measurement: weightAndImpedance) == .impedance)
        #expect(RecordMetricProgression.nextStage(after: .impedance, measurement: weightAndImpedance) == nil)
    }

    @Test func readingStatesCanCancelButSubmissionCannot() {
        #expect(RecordCircleState.ready.isActionable)
        #expect(RecordCircleState.saved.isActionable)
        #expect(RecordCircleState.recordingFailed("Bluetooth unavailable").isActionable)
        #expect(RecordCircleState.submissionFailed("Server unavailable").isActionable)
        #expect(RecordCircleState.connecting("Searching").isActionable)
        #expect(RecordCircleState.weight(73.5).isActionable)
        #expect(RecordCircleState.impedance(510).isActionable)
        #expect(RecordCircleState.heartRate(72, isSubmitting: false).isActionable)
        #expect(!RecordCircleState.heartRate(72, isSubmitting: true).isActionable)
    }

    @Test @MainActor func idleTimerLeaseRestoresThePreviousValue() {
        let controller = IdleTimerControllerStub(isIdleTimerDisabled: false)
        let lease = IdleTimerLease(controller: controller)

        #expect(controller.isIdleTimerDisabled)

        lease.release()

        #expect(!controller.isIdleTimerDisabled)
    }

    @Test @MainActor func idleTimerLeasePreservesAnExistingDisabledTimer() {
        let controller = IdleTimerControllerStub(isIdleTimerDisabled: true)
        let lease = IdleTimerLease(controller: controller)

        lease.release()

        #expect(controller.isIdleTimerDisabled)
    }
}

@MainActor
private final class IdleTimerControllerStub: IdleTimerControlling {
    var isIdleTimerDisabled: Bool

    init(isIdleTimerDisabled: Bool) {
        self.isIdleTimerDisabled = isIdleTimerDisabled
    }
}
