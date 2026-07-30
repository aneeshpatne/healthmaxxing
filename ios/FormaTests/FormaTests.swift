//
//  FormaTests.swift
//  FormaTests
//
//  Created by Aneesh Patne on 19/06/26.
//

import Testing
import Foundation
@testable import Forma

struct FormaChartStyleTests {
    @Test func paddedDomainAddsHeadroomForFlatData() {
        let domain = FormaChartStyle.paddedDomain(values: [72, 72, 72])

        #expect(domain.lowerBound < 72)
        #expect(domain.upperBound > 72)
    }

    @Test func paddedDomainCanIncludeZero() {
        let domain = FormaChartStyle.paddedDomain(values: [4, 8, 12], includeZero: true)

        #expect(domain.lowerBound < 0)
        #expect(domain.upperBound > 12)
    }

    @Test func axisDatesUseFirstMiddleAndLast() {
        let dates = (0..<7).map { Date(timeIntervalSinceReferenceDate: Double($0 * 86_400)) }

        #expect(FormaChartStyle.axisDates(dates) == [dates[0], dates[3], dates[6]])
    }

    @Test func nearestDateSnapsToARealSample() {
        let dates = [
            Date(timeIntervalSinceReferenceDate: 0),
            Date(timeIntervalSinceReferenceDate: 100),
            Date(timeIntervalSinceReferenceDate: 200)
        ]

        let selection = Date(timeIntervalSinceReferenceDate: 141)
        #expect(FormaChartStyle.nearestDate(to: selection, in: dates) == dates[1])
    }

    @Test func steppedDateMovesAcrossSamplesAndClampsAtBounds() {
        let dates = [
            Date(timeIntervalSinceReferenceDate: 0),
            Date(timeIntervalSinceReferenceDate: 100),
            Date(timeIntervalSinceReferenceDate: 200)
        ]

        #expect(FormaChartStyle.steppedDate(from: dates[1], offset: 1, in: dates) == dates[2])
        #expect(FormaChartStyle.steppedDate(from: dates[0], offset: -1, in: dates) == dates[0])
        #expect(FormaChartStyle.steppedDate(from: dates[2], offset: 1, in: dates) == dates[2])
    }
}

struct FormaFeedbackPolicyTests {
    @Test func routineSelectionIsHapticOnly() {
        #expect(FormaUIFeedback.selection.playsSound == false)
        #expect(FormaUIFeedback.softImpact.playsSound == false)
    }

    @Test func confirmationsAndRecordMilestonesKeepSound() {
        #expect(FormaUIFeedback.confirm.playsSound)
        #expect(FormaUIFeedback.success.playsSound)
        #expect(RecordFeedbackEvent.metric(.weight).playsSound)
        #expect(RecordFeedbackEvent.success.playsSound)
    }
}
