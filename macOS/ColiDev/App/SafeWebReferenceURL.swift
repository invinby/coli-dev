import Foundation

enum SafeWebReferenceURL {
    private static let allowedHosts: Set<String> = [
        "animaldiversity.org",
        "csrc.nist.gov",
        "docs.python.org",
        "learnenglish.britishcouncil.org",
        "medlineplus.gov",
        "openstax.org",
        "www.genome.gov",
        "www.ncbi.nlm.nih.gov",
        "www.nist.gov",
        "www.sqlite.org",
    ]

    private static let allowedRepositoryReferences: Set<String> = [
        "raw.githubusercontent.com/elifesciences/elife-article-xml/master/articles/elife-81613-v1.xml"
    ]

    private static let allowedStudyReferences: Set<String> = [
        "www.sciencedirect.com/science/article/pii/S1095643325000789",
        "pubmed.ncbi.nlm.nih.gov/40393560/",
    ]

    static func parse(_ rawValue: String) -> URL? {
        guard let components = URLComponents(string: rawValue),
              components.scheme?.lowercased() == "https",
              let host = components.host,
              !host.isEmpty,
              components.user == nil,
              components.password == nil,
              components.port == nil,
              components.query == nil,
              components.fragment == nil,
              allowedHosts.contains(host.lowercased())
                || allowedRepositoryReferences.contains("\(host.lowercased())\(components.path)")
                || allowedStudyReferences.contains("\(host.lowercased())\(components.path)") else {
            return nil
        }
        return components.url
    }
}
