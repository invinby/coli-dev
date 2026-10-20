import Foundation

@main
enum YouTubeEmbedURLVerification {
    static func main() {
        let russianURL = YouTubeEmbedURLBuilder.make(
            videoID: "ZA_D4O6l1lo",
            captionLanguage: "ru"
        )
        precondition(russianURL?.host == "www.youtube.com")
        precondition(russianURL?.path == "/embed/ZA_D4O6l1lo")
        let russianQuery = URLComponents(url: russianURL!, resolvingAgainstBaseURL: false)!
            .queryItems!
        precondition(russianQuery.first(where: { $0.name == "cc_lang_pref" })?.value == "ru")
        precondition(russianQuery.first(where: { $0.name == "cc_load_policy" })?.value == "1")
        precondition(russianQuery.first(where: { $0.name == "autoplay" })?.value == "0")
        precondition(russianQuery.first(where: { $0.name == "origin" })?.value == "https://github.com")

        let englishURL = YouTubeEmbedURLBuilder.make(
            videoID: "ZA_D4O6l1lo",
            captionLanguage: "en"
        )
        let englishQuery = URLComponents(url: englishURL!, resolvingAgainstBaseURL: false)!
            .queryItems!
        precondition(englishQuery.first(where: { $0.name == "cc_lang_pref" })?.value == "en")

        precondition(YouTubeEmbedURLBuilder.make(videoID: "not-a-video", captionLanguage: "ru") == nil)
        precondition(YouTubeEmbedURLBuilder.make(videoID: "ZA_D4O6l1lo", captionLanguage: "fr") == nil)
        print("Bilingual YouTube caption preference checks passed.")
    }
}
