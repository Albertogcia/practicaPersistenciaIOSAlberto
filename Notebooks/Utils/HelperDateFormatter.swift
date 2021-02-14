//
//  HelperDateFormatter.swift
//  Notebooks
//
//  Created by Daniel Torres on 2/1/21.
//

import Foundation

enum HelperDateFormatter {
    static var format: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    static func textFrom(date: Date) -> String {
        return format.string(from: date)
    }
}
