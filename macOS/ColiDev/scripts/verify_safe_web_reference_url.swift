import Foundation

@main
enum SafeWebReferenceURLVerification {
    static func main() {
        let valid = SafeWebReferenceURL.parse("https://learnenglish.britishcouncil.org/free-resources/grammar/b1-b2/conditionals-zero-first-second")
        precondition(valid?.scheme == "https", "a canonical HTTPS lesson source should be linkable")
        for source in [
            "https://medlineplus.gov/genetics/understanding/basics/dna/",
            "https://openstax.org/books/prealgebra-2e/pages/9-4-use-properties-of-rectangles-triangles-and-trapezoids",
            "https://openstax.org/books/college-algebra-2e/pages/1-6-rational-expressions",
            "https://openstax.org/books/college-algebra-2e/pages/5-6-rational-functions",
            "https://openstax.org/books/college-algebra-2e/pages/7-1-systems-of-linear-equations-two-variables",
            "https://docs.python.org/3/library/bisect.html",
            "https://www.genome.gov/genetics-glossary/genotype",
            "https://www.genome.gov/genetics-glossary/Gene-Expression",
            "https://www.genome.gov/genetics-glossary/Gene-Regulation",
            "https://www.genome.gov/genetics-glossary/Promoter",
            "https://www.genome.gov/genetics-glossary/Chromatid",
            "https://www.ncbi.nlm.nih.gov/books/NBK26854/",
            "https://www.ncbi.nlm.nih.gov/books/NBK550206/",
            "https://www.ncbi.nlm.nih.gov/books/NBK9842/",
            "https://openstax.org/books/biology-2e/pages/10-2-the-cell-cycle",
            "https://openstax.org/books/biology-2e/pages/33-1-animal-form-and-function",
            "https://openstax.org/books/biology-2e/pages/34-1-digestive-systems",
            "https://openstax.org/books/biology-2e/pages/38-1-types-of-skeletal-systems",
            "https://openstax.org/books/biology-2e/pages/39-1-systems-of-gas-exchange",
            "https://openstax.org/books/biology-2e/pages/43-2-fertilization",
            "https://csrc.nist.gov/glossary/term/algorithm",
            "https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9",
            "https://www.sqlite.org/lang_transaction.html",
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
