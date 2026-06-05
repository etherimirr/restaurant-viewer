import XCTest

/// End-to-end UI tests driving the real app in the simulator. The app is
/// launched with `-uitest-mock`, which injects deterministic restaurant data
/// (no network, no location prompt) — see `AppEnvironment` / `UITestMocks`.
///
/// Mock data is ordered: the default term yields cards titled "Bistro 01",
/// "Bistro 02", … and a search for "ramen" yields "Ramen 01", … The top card
/// carries the `topCardTitle` identifier, so we can assert which card is in
/// front by reading its label.
final class RestaurantViewerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Must match AppEnvironment.uiTestMockArgument in the app target. UI
        // tests are black-box (separate process), so the string is duplicated
        // here rather than imported.
        app.launchArguments += ["-uitest-mock"]
        app.launch()
    }

    private var topCardTitle: XCUIElement { app.staticTexts["topCardTitle"] }
    private var nextButton: XCUIElement { app.buttons["nextButton"] }
    private var previousButton: XCUIElement { app.buttons["previousButton"] }

    /// The first card loads and shows the first mock restaurant.
    func testInitialCardLoads() {
        XCTAssertTrue(topCardTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(topCardTitle.label, "Bistro 01")
        XCTAssertTrue(nextButton.isEnabled)
        // Previous is disabled on the first card.
        XCTAssertFalse(previousButton.isEnabled)
    }

    /// Next advances the front card; Previous brings the prior one back.
    func testNextAndPreviousNavigateTheStack() {
        XCTAssertTrue(topCardTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(topCardTitle.label, "Bistro 01")

        nextButton.tap()
        XCTAssertTrue(waitForTopCard(toEqual: "Bistro 02"))
        XCTAssertTrue(previousButton.isEnabled)

        nextButton.tap()
        XCTAssertTrue(waitForTopCard(toEqual: "Bistro 03"))

        previousButton.tap()
        XCTAssertTrue(waitForTopCard(toEqual: "Bistro 02"))
    }

    /// The feed keeps producing cards well past the first page (pagination).
    func testEndlessPaginationLoadsMoreCards() {
        XCTAssertTrue(topCardTitle.waitForExistence(timeout: 5))
        for _ in 0..<60 { nextButton.tap() }
        // 60 advances from "Bistro 01" lands on "Bistro 61" — only reachable if
        // a second page was fetched seamlessly.
        XCTAssertTrue(waitForTopCard(toEqual: "Bistro 61"))
    }

    /// Submitting a new term resets the stack and refetches.
    func testSearchUpdatesTheStack() {
        XCTAssertTrue(topCardTitle.waitForExistence(timeout: 5))

        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.press(forDuration: 1.0)
        if app.menuItems["Select All"].exists { app.menuItems["Select All"].tap() }
        field.typeText("ramen\n")

        XCTAssertTrue(waitForTopCard(toEqual: "Ramen 01"))
    }

    /// The heart toggles favorite state (its accessibility label flips).
    func testFavoriteToggle() {
        XCTAssertTrue(topCardTitle.waitForExistence(timeout: 5))
        let favorite = app.buttons["favoriteButton"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5))

        // Wait until the heart has settled (card entrance animation finished)
        // before tapping, otherwise the first tap can be swallowed mid-animation.
        XCTAssertTrue(waitUntilHittable(favorite))
        XCTAssertEqual(favorite.label, "Add to favorites")

        favorite.tap()
        XCTAssertTrue(waitForLabel(of: favorite, toEqual: "Remove from favorites"))
        favorite.tap()
        XCTAssertTrue(waitForLabel(of: favorite, toEqual: "Add to favorites"))
    }

    // MARK: - Helpers

    /// Polls the top card's label until it matches (the slide animation means
    /// the label updates a beat after the tap).
    private func waitForTopCard(toEqual expected: String, timeout: TimeInterval = 5) -> Bool {
        waitForLabel(of: topCardTitle, toEqual: expected, timeout: timeout)
    }

    private func waitForLabel(of element: XCUIElement, toEqual expected: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits until an element is actually hittable (e.g. its entrance animation
    /// has finished), guarding against taps being swallowed mid-transition.
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
