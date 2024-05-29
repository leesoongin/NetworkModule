//
//  CommonNetworkError.swift
//
//
//  Created by 이숭인 on 5/29/24.
//

import Foundation

public enum CommonNetworkError: Error {
    case unknown
    case invalidURL
    case invalidResponse
    case invalidStatus(code: Int)
    case cancelled
}
