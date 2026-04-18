import Foundation
import AppStoreConnect_Swift_SDK

/// User-facing classification of App Store Connect API failures. The SDK
/// throws `APIProvider.Error.requestFailure(statusCode, errorResponse, _)` for
/// HTTP errors, which becomes opaque to users unless we unwrap the status code
/// and translate it into actionable guidance.
enum ASCError: LocalizedError {
    case missingCredentials
    case unauthorized
    case forbidden
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(Int)
    case network(Error)
    case other(Error)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Missing API credentials — configure in the Xcode Cloud tab."
        case .unauthorized:
            return "App Store Connect API key was rejected (401). Regenerate the key in App Store Connect and re-paste it in Settings."
        case .forbidden:
            return "App Store Connect API key lacks permission (403). Grant the key the Developer role or higher."
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limited by App Store Connect API — retry in \(Int(retryAfter))s."
            }
            return "Rate limited by App Store Connect API — retry shortly."
        case .serverError(let code):
            return "App Store Connect API server error (\(code)). Try again later."
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .other(let error):
            return error.localizedDescription
        }
    }
}

/// Runs App Store Connect SDK requests with bounded exponential-backoff retry
/// for transient failures (429, 5xx, network), and converts the SDK's opaque
/// `requestFailure` into a typed `ASCError` so the UI can surface actionable
/// messages per status code.
enum ASCRequestRunner {
    static let maxAttempts = 3

    static func run<T>(_ block: (APIProvider) async throws -> T) async throws -> T {
        guard let credentials = ASCCredentialStore.current() else {
            throw ASCError.missingCredentials
        }
        let config = try APIConfiguration(
            issuerID: credentials.issuerID,
            privateKeyID: credentials.keyID,
            privateKey: credentials.privateKey
        )
        let provider = APIProvider(configuration: config)

        var lastError: ASCError = .other(NSError(domain: "ASC", code: -1))
        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                let base = pow(2.0, Double(attempt - 1))
                let delay = retryDelay(for: lastError, defaultSeconds: base)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            do {
                return try await block(provider)
            } catch {
                let classified = classify(error)
                lastError = classified
                if !shouldRetry(classified) {
                    throw classified
                }
            }
        }
        throw lastError
    }

    private static func retryDelay(for error: ASCError, defaultSeconds: Double) -> Double {
        if case .rateLimited(let retryAfter) = error, let retryAfter {
            return min(retryAfter, 30)
        }
        return defaultSeconds
    }

    private static func shouldRetry(_ error: ASCError) -> Bool {
        switch error {
        case .rateLimited, .serverError, .network:
            return true
        case .missingCredentials, .unauthorized, .forbidden, .other:
            return false
        }
    }

    private static func classify(_ error: Error) -> ASCError {
        if let ascError = error as? ASCError {
            return ascError
        }
        if let apiError = error as? APIProvider.Error {
            switch apiError {
            case .requestFailure(let statusCode, _, _):
                return classifyStatus(statusCode)
            case .requestExecutorError(let underlying):
                return classifyNetwork(underlying, fallback: apiError)
            default:
                return .other(apiError)
            }
        }
        return classifyNetwork(error, fallback: error)
    }

    private static func classifyNetwork(_ error: Error, fallback: Error) -> ASCError {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .network(error)
        }
        return .other(fallback)
    }

    private static func classifyStatus(_ code: Int) -> ASCError {
        switch code {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 429: return .rateLimited(retryAfter: nil)
        case 500...599: return .serverError(code)
        default: return .other(NSError(
            domain: "ASC",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: "Request failed with status \(code)."]
        ))
        }
    }
}
