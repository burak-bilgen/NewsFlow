import Foundation

protocol NewsAPIClientProtocol {
    func request<Response: NewsAPIResponseEnvelope>(
        _ responseType: Response.Type,
        endpoint: NewsAPIEndpoint
    ) async throws -> Response
}

final class NewsAPIClient: NewsAPIClientProtocol {
    private let session: URLSession
    private let requestBuilder: NewsAPIRequestBuilding
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        requestBuilder: NewsAPIRequestBuilding,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.decoder = decoder
    }

    func request<Response: NewsAPIResponseEnvelope>(
        _ responseType: Response.Type,
        endpoint: NewsAPIEndpoint
    ) async throws -> Response {
        let request: URLRequest
        do {
            request = try requestBuilder.makeRequest(endpoint: endpoint)
        } catch let error as NewsAPIError {
            throw error
        } catch {
            throw NewsAPIError.invalidURL
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw NewsAPIError.cancelled
        } catch let error as URLError where error.code == .cancelled {
            throw NewsAPIError.cancelled
        } catch {
            throw NewsAPIError.network
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NewsAPIError.invalidResponse
        }

        guard !data.isEmpty else {
            throw NewsAPIError.emptyResponse
        }

        let decoded: Response
        do {
            decoded = try decoder.decode(Response.self, from: data)
        } catch {
            throw NewsAPIError.decoding
        }

        guard (200...299).contains(httpResponse.statusCode), decoded.status == "ok" else {
            throw NewsAPIError.apiStatus(code: decoded.code, message: decoded.message)
        }

        return decoded
    }
}

protocol NewsAPIResponseEnvelope: Decodable {
    var status: String { get }
    var code: String? { get }
    var message: String? { get }
}
