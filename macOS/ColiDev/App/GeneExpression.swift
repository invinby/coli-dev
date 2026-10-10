import Foundation

struct GeneExpressionSnapshot: Equatable {
    let promoterIsActive: Bool
    let messengerRNA: String?
    let peptide: [String]?
}

enum GeneExpressionPractice {
    static let templateStrand = "TAC GGA ACT"

    static func makeStopCodonAttempt() -> InteractivePredictionAttempt {
        guard let attempt = InteractivePredictionAttempt(optionCount: 3, answerOriginalIndex: 1) else {
            preconditionFailure("The stop-codon question must have one valid answer.")
        }
        return attempt
    }

    static func transcribe(templateDNA: String) -> String? {
        let bases = templateDNA.uppercased().filter { !$0.isWhitespace }
        guard !bases.isEmpty, bases.count.isMultiple(of: 3) else { return nil }

        let complement: [Character: Character] = ["A": "U", "T": "A", "C": "G", "G": "C"]
        var transcript: [Character] = []
        transcript.reserveCapacity(bases.count)
        for base in bases {
            guard let rnaBase = complement[base] else { return nil }
            transcript.append(rnaBase)
        }
        return stride(from: 0, to: transcript.count, by: 3).map { index in
            String(transcript[index..<min(index + 3, transcript.count)])
        }.joined(separator: " ")
    }

    static func translate(messengerRNA: String) -> [String]? {
        let codons = messengerRNA.uppercased()
            .split(whereSeparator: \.isWhitespace)
            .joined()
        guard !codons.isEmpty, codons.count.isMultiple(of: 3) else { return nil }

        let stopCodons: Set<String> = ["UAA", "UAG", "UGA"]
        var aminoAcids: [String] = []
        var foundStart = false
        for offset in stride(from: 0, to: codons.count, by: 3) {
            let start = codons.index(codons.startIndex, offsetBy: offset)
            let end = codons.index(start, offsetBy: 3)
            let codon = String(codons[start..<end])

            if !foundStart {
                guard codon == "AUG" else { return nil }
                foundStart = true
                aminoAcids.append("Met")
                continue
            }
            if stopCodons.contains(codon) {
                aminoAcids.append("Stop")
                return aminoAcids
            }
            guard codon == "CCU" else { return nil }
            aminoAcids.append("Pro")
        }
        return nil
    }

    static func snapshot(promoterIsActive: Bool) -> GeneExpressionSnapshot {
        guard promoterIsActive,
              let messengerRNA = transcribe(templateDNA: templateStrand),
              let peptide = translate(messengerRNA: messengerRNA) else {
            return GeneExpressionSnapshot(promoterIsActive: promoterIsActive, messengerRNA: nil, peptide: nil)
        }
        return GeneExpressionSnapshot(
            promoterIsActive: true,
            messengerRNA: messengerRNA,
            peptide: peptide
        )
    }
}
