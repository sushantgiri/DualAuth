//
//  NormalizedEthrDID.swift
//  Smart ID Card
//
//  Created by Sushant Giri on 21/06/2021.
//

import Foundation

public enum NormalizedEthrDIDError: Error
{
    case invalidDIDCandidateParam
    case invalidDIDType
    case notDID
    case sanityCheckFailure
}

public struct NormalizedEthrDID
{
    /// the result of processing the DID
    /// empty string if invalid didCandidate was passed to constructor
    var value = ""
    
    /// will be non-nil if constuct fails to process the DID
    var error: NormalizedEthrDIDError?

    public let didParsePattern = try? NSRegularExpression(pattern: "^(did:)?((\\w+):)?((0x)([0-9a-fA-F]{40}))",
                                                          options: .caseInsensitive)

    public init(didCandidate: String)
    {
        let range = NSRange(location: 0, length: didCandidate.count)
        let textCheckingResults = self.didParsePattern?.matches(in: didCandidate, options: [], range: range)
        guard let textCheckingResult = textCheckingResults?.first else
        {
            self.error = NormalizedEthrDIDError.invalidDIDCandidateParam

            return
        }
        
        var matches = [String]()
        for index in 1 ..< textCheckingResult.numberOfRanges
        {
            let range = Range(textCheckingResult.range(at: index), in: didCandidate)
            if range != nil
            {
                let stringSlice = didCandidate[range!]
                let match = String(stringSlice)
                matches.append(match)
            }
        }
        
        guard 0 < matches.count else
        {
            self.error = NormalizedEthrDIDError.notDID

            return
        }
        
        let didHeader = self.didHeader(matches: matches)
        let didType = self.didType(matches: matches)
        if !didType.isEmpty && !didType.starts(with: "dual")
        {
            self.error = NormalizedEthrDIDError.invalidDIDType

            return
        }

        if didHeader.isEmpty && !didType.isEmpty
        {
            self.error = NormalizedEthrDIDError.notDID

            return
        }
        
        guard let hexDigits = matches.last, hexDigits.count == 40 else
        {
            self.error = NormalizedEthrDIDError.sanityCheckFailure

            return
        }
        
        self.value = "did:dual:0x\(hexDigits)"
    }
    
    private func didHeader(matches: [String]) -> String
    {
        return matches.filter(
        { (item) -> Bool in
            return item.starts(with: "did")
        }).first ?? ""
    }
    
    private func didType(matches: [String]) -> String
    {
        return matches.filter(
        { (item) -> Bool in
            return item.starts(with: "dual")
        }).first ?? ""
    }
}

