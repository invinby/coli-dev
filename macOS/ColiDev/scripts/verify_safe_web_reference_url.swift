import Foundation

@main
enum SafeWebReferenceURLVerification {
    static func main() {
        let valid = SafeWebReferenceURL.parse("https://learnenglish.britishcouncil.org/free-resources/grammar/b1-b2/conditionals-zero-first-second")
        precondition(valid?.scheme == "https", "a canonical HTTPS lesson source should be linkable")
        for source in [
            "https://medlineplus.gov/genetics/understanding/basics/dna/",
            "https://www.genome.gov/genetics-glossary/genotype",
            "https://csrc.nist.gov/glossary/term/algorithm",
            "https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9",
            "https://raw.githubusercontent.com/elifesciences/elife-article-xml/master/articles/elife-81613-v1.xml",
        ] {
            precondition(SafeWebReferenceURL.parse(source) != nil, "official lesson references should be linkable: \(source)")
        }
        precondition(SafeWebReferenceURL.parse("http://learnenglish.britishcouncil.org/path") == nil, "plain HTTP should not be linkable")
        precondition(SafeWebReferenceURL.parse("https://user:secret@example.org/source") == nil, "userinfo should be rejected")
        precondition(SafeWebReferenceURL.parse("https://example.org/source?token=secret") == nil, "query strings should be rejected")
        precondition(SafeWebReferenceURL.parse("https://example.org/source#private") == nil, "fragments should be rejected")
        precondition(SafeWebReferenceURL.parse("https://raw.githubusercontent.com/someone/another-repo/main/README.md") == nil, "arbitrary GitHub raw pages should not be linkable")
        precondition(SafeWebReferenceURL.parse("https://example.org/source") == nil, "unknown hosts should not be linkable")
        precondition(SafeWebReferenceURL.parse("not a URL") == nil, "malformed references should be rejected")
        print("Safe web reference URL checks passed.")
    }
}
