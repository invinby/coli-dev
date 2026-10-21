import Foundation

enum YouTubeEmbedURLBuilder {
    static let appOrigin = "https://com.colidev.learningstudio"
    static let appReferer = "\(appOrigin)/"

    static func make(videoID: String, captionLanguage: String) -> URL? {
        guard videoID.range(of: #"^[A-Za-z0-9_-]{11}$"#, options: .regularExpression) != nil,
              captionLanguage == "ru" || captionLanguage == "en",
              var components = URLComponents(string: "https://www.youtube.com/embed/\(videoID)") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "autoplay", value: "0"),
            URLQueryItem(name: "controls", value: "1"),
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "cc_load_policy", value: "1"),
            URLQueryItem(name: "cc_lang_pref", value: captionLanguage),
            URLQueryItem(name: "origin", value: appOrigin)
        ]
        return components.url
    }
}
