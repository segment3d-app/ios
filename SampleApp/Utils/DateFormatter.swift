//
//  DateFormatter.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import Foundation

func IsoStringToTimeInterval(isoDateString: String) -> TimeInterval? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSS'Z'"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)  // Set timezone to UTC

    if let date = dateFormatter.date(from: isoDateString) {
        return date.timeIntervalSince1970
    } else {
        return nil
    }
}
