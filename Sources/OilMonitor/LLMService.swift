import Foundation

@MainActor
final class LLMService: ObservableObject {
    static let shared = LLMService()
    private init() {}

    // MARK: - Config (read fresh per call)

    private var baseURL: String {
        UserDefaults.standard.string(forKey: "llmBaseURL") ?? ""
    }
    private var modelName: String {
        UserDefaults.standard.string(forKey: "llmModelName") ?? ""
    }

    // MARK: - Generate Strategy

    func generatePlan(from signals: LocalSignals) async throws -> StrategyPlan {
        guard !baseURL.isEmpty, !modelName.isEmpty else { throw LLMError.notConfigured }

        let systemMsg = """
        你是一名能源市场分析助手。已知价格传导链：原油（Brent/WTI）领先 RBOB 汽油期货，\
        RBOB 领先美国零售泵价约 1-2 周。基于提供的量化信号，判断用户"现在应立即加油"还是"稍后再加"，\
        并给出 1-2 周趋势展望。不要输出任何金额或省钱数字。\
        必须只返回一个 JSON 对象，不要包含解释、Markdown 或代码块。\
        JSON 结构如下（所有字段必须存在）：\
        {"recommendation":"fill_now|wait|neutral","confidence":"low|medium|high",\
        "trend":"rising|falling|stable","outlook":"1-2句中文展望",\
        "reasoning":"1-2句中文理由，引用关键信号","estimatedPriceChangePct":数字}
        """

        let userMsg = buildSignalJSON(signals)
        let body: [String: Any] = [
            "model": modelName,
            "temperature": 0.2,
            "max_tokens": 400,
            "response_format": ["type": "json_object"],
            "format": "json",
            "messages": [
                ["role": "system", "content": systemMsg],
                ["role": "user",   "content": userMsg]
            ]
        ]

        let req = try makeRequest(body: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw LLMError.unreachable("无响应") }
        guard http.statusCode == 200 else {
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? ""
            throw LLMError.httpStatus(http.statusCode, snippet)
        }

        let content = try extractContent(from: data)
        let llmResp = try parseJSON(content)

        return StrategyPlan(
            recommendation: llmResp.recommendation,
            confidence: llmResp.confidence,
            trend: llmResp.trend,
            outlook: llmResp.outlook,
            reasoning: llmResp.reasoning,
            estimatedPriceChangePct: llmResp.estimatedPriceChangePct,
            generatedAt: Date(),
            modelName: modelName
        )
    }

    // MARK: - Test Connection

    func testConnection() async -> Result<String, LLMError> {
        guard !baseURL.isEmpty, !modelName.isEmpty else { return .failure(.notConfigured) }
        let body: [String: Any] = [
            "model": modelName,
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]]
        ]
        do {
            let req = try makeRequest(body: body)
            let start = Date()
            let (_, response) = try await URLSession.shared.data(for: req)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            guard let http = response as? HTTPURLResponse else { return .failure(.unreachable("无响应")) }
            if http.statusCode == 200 {
                return .success("连接成功 · \(modelName) · \(ms)ms")
            } else {
                return .failure(.httpStatus(http.statusCode, ""))
            }
        } catch let e as LLMError {
            return .failure(e)
        } catch {
            return .failure(.unreachable(error.localizedDescription))
        }
    }

    // MARK: - Private Helpers

    private func makeRequest(body: [String: Any]) throws -> URLRequest {
        let endpoint = baseURL.hasSuffix("/") ? baseURL + "chat/completions"
                                             : baseURL + "/chat/completions"
        guard let url = URL(string: endpoint) else { throw LLMError.badURL }
        var req = URLRequest(url: url, timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = KeychainHelper.apiKey() {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    private func extractContent(from data: Data) throws -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw LLMError.emptyResponse }
        return content
    }

    private func parseJSON(_ content: String) throws -> LLMStrategyResponse {
        // Strip possible markdown fences, extract first {...}
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let extracted: String
        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            extracted = String(trimmed[start...end])
        } else {
            extracted = trimmed
        }
        guard let data = extracted.data(using: .utf8) else {
            throw LLMError.malformedJSON(String(content.prefix(100)))
        }
        do {
            return try JSONDecoder().decode(LLMStrategyResponse.self, from: data)
        } catch {
            throw LLMError.malformedJSON(String(content.prefix(100)))
        }
    }

    private func buildSignalJSON(_ s: LocalSignals) -> String {
        var dict: [String: Any] = [
            "as_of": ISO8601DateFormatter().string(from: s.asOf),
            "window_days": s.windowDays,
            "data_points": s.dataPointCount,
            "leadlag_days": s.leadLagDays,
            "vehicle_tank_gallons": s.tankGallons,
            "vehicle_weekly_miles": s.weeklyMiles,
            "vehicle_mpg": s.mpg,
            "vehicle_weekly_fuel_gallons": String(format: "%.1f", s.weeklyFuelGallons)
        ]
        if let v = s.brentMomentumPct  { dict["brent_momentum_pct"]    = round(v * 100) / 100 }
        if let v = s.wtiMomentumPct    { dict["wti_momentum_pct"]      = round(v * 100) / 100 }
        if let v = s.rbobMomentumPct   { dict["rbob_momentum_pct"]     = round(v * 100) / 100 }
        if let v = s.rbobShortMomentumPct { dict["rbob_5d_momentum_pct"] = round(v * 100) / 100 }
        if let v = s.crudeRbobLeadLagCorr { dict["crude_rbob_leadlag_corr"] = round(v * 100) / 100 }
        if let v = s.crackSpreadProxy  { dict["crack_spread_proxy"]    = round(v * 100) / 100 }
        if let v = s.crackSpreadChange { dict["crack_spread_change"]   = round(v * 100) / 100 }
        if s.dataPointCount < 8        { dict["data_warning"]          = "insufficient_history" }
        let data = (try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Errors

    enum LLMError: LocalizedError, Equatable {
        case notConfigured
        case badURL
        case unreachable(String)
        case httpStatus(Int, String)
        case emptyResponse
        case malformedJSON(String)
        case insufficientData

        var errorDescription: String? {
            switch self {
            case .notConfigured:       return "请先在设置中配置推理服务器地址和模型名称"
            case .badURL:              return "URL 格式错误"
            case .unreachable(let d):  return "无法连接到服务器：\(d)"
            case .httpStatus(let c, _): return "服务器返回错误状态码 \(c)"
            case .emptyResponse:       return "服务器返回了空响应"
            case .malformedJSON(let s): return "模型返回格式异常，请重试（\(s)）"
            case .insufficientData:    return "历史数据不足，请等待更多数据后再试"
            }
        }
    }
}
