//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(RawSyntax) import SwiftSyntax
import XCTest

class IdentifierTests: XCTestCase {
  public func testIdentifierInit() {
    let someToken = TokenSyntax(stringLiteral: "someToken")
    XCTAssertNotNil(Identifier(someToken))

    let nonIdentifierToken = DeclSyntax("let a = 1").firstToken(viewMode: .all)!
    XCTAssertNil(Identifier(nonIdentifierToken))
  }

  public func testName() {
    let basicToken = TokenSyntax(stringLiteral: "basicToken")
    XCTAssertEqual(Identifier(basicToken)?.name, "basicToken")

    let backtickedToken = TokenSyntax(stringLiteral: "`backtickedToken`")
    XCTAssertEqual(Identifier(backtickedToken)?.name, "backtickedToken")

    let multiBacktickedToken = TokenSyntax(stringLiteral: "```multiBacktickedToken```")
    XCTAssertEqual(Identifier(multiBacktickedToken)?.name, "``multiBacktickedToken``")

    let unicodeNormalizedToken = TokenSyntax(stringLiteral: "\u{e0}")  // "a`"
    XCTAssertEqual(Identifier(unicodeNormalizedToken)?.name, "\u{61}\u{300}")  // "à"
  }

  public func testHashableMatchesEquality() {
    // Each token lives in its own arena, so these also compare identifiers from different trees.
    let equalPairs: [(TokenSyntax, TokenSyntax)] = [
      ("Inner", "`Inner`"),
      ("Inner", "Inner"),
      ("\u{e0}", "\u{61}\u{300}"),
      (.dollarIdentifier("$01"), .dollarIdentifier("$1")),
    ]
    withExtendedLifetime(equalPairs) { equalPairs in
      for (lhsToken, rhsToken) in equalPairs {
        let lhs = Identifier(lhsToken)
        let rhs = Identifier(rhsToken)
        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual(lhs.hashValue, rhs.hashValue)
        XCTAssertEqual(Set([lhs, rhs]).count, 1)
      }
    }

    let token = TokenSyntax(stringLiteral: "Inner")
    withExtendedLifetime(token) { token in
      let canonical = Identifier(canonicalName: "Inner")
      XCTAssertEqual(Identifier(token), canonical)
      XCTAssertEqual(Identifier(token)?.hashValue, canonical.hashValue)
    }
  }

  public func testHashableKeepsUnequalIdentifiersApart() {
    let unequalPairs: [(TokenSyntax, TokenSyntax)] = [
      ("Inner", "inner"),
      ("``Inner``", "Inner"),
      (.dollarIdentifier("$01"), .dollarIdentifier("$10")),
    ]
    withExtendedLifetime(unequalPairs) { unequalPairs in
      for (lhsToken, rhsToken) in unequalPairs {
        let lhs = Identifier(lhsToken)
        let rhs = Identifier(rhsToken)
        XCTAssertNotEqual(lhs, rhs)
        XCTAssertEqual(Set([lhs, rhs]).count, 2)
      }
    }
  }

  public func testIdentifier() {
    let token = TokenSyntax(stringLiteral: "sometoken")
    withExtendedLifetime(token) { token in
      XCTAssertEqual(token.identifier?.raw.name, SyntaxText("sometoken"))
    }
  }

  public func testTokenSyntaxIdentifier() throws {
    let tokenSyntax = TokenSyntax(stringLiteral: "sometoken")
    XCTAssertEqual(tokenSyntax.identifier, Identifier(tokenSyntax))

    let nonIdentifierToken = try XCTUnwrap(DeclSyntax("let a = 1").firstToken(viewMode: .all))
    XCTAssertNil(nonIdentifierToken.identifier)
  }
}
