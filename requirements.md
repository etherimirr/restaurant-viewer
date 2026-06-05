# Fini iOS Development Internship — Interview Assignment 2026

**Source**: https://docs.google.com/document/d/1WPlTGnl9zQgXEuheyHcXqZzRcPnp0IuIN1W8X-vY4S0/edit?tab=t.0
**Captured**: 2026-06-04
**Role**: Jr. iOS Developer Intern @ Fini
**Recruiter**: Ashley Nader (Founder)

---

## Internship Take-Home Challenge

**Purpose**: Learn how you think, problem-solve, and bring ideas to life. Looking for creativity, strategic thinking, and clarity in design process, not perfection. Be thoughtful, scrappy, and have fun with it.

**Timebox**: Do not spend more than **2-3 hours** total.

**How to Submit**: Deliver via a **view-only Google Doc, GitHub or similar file link**. All links must be set to **public** before submitting.

**AI tools**: You are welcome to use AI tools to support you in this process, but they still want to see how you think and break down problems.

---

## Mobile Take Home Interview — Restaurant Viewer

### Summary

Spend up to 3 hours building an app that displays a card-based image viewer that shows restaurants in the local area of the device.

### Requirements

- Use the **Location Service** (Core Location as an example on iOS) and the **Yelp API** to load restaurants in the current area of the device.
- The main view will contain a **stack of cards**.
- Each card should display the **name of the restaurant, the restaurant image, and the rating**.
- The viewer should have **two buttons**, one for the **next** card and one for the **previous** one.
- The **next button dismisses the current card at the top of the stack**. Dismissal should animate the card offscreen to the left revealing the next card.
- The **previous button brings back the previously shown card**. This should animate the previous card back on screen from the left.
- Your implementation should work on: **iPhone and plus sized devices for iOS. SDK Level >= 23 and multiple screen sizes for Android.**
- Your implementation should **automatically load more results from the Yelp API** when the user reaches near the end of the card stack.
- The feed should allow the user to **browse endlessly**. When the user nears the end of the card stack, the app should automatically load more results from the Yelp API. This should load seamlessly in the background with minimal impact to the user experience.
- The user interface **does not need to match the demonstration gif exactly**, feel free to be creative.

### Bonus

- (BONUS) Your implementation works in **landscape mode**.
- (BONUS) Add an **input field to change the query** from just restaurants to anything.
- (BONUS) Add a **toggle to favorite each restaurant and persist** the favorited values.

---

## Guidelines / How we will grade this

- Were you able to meet the requirements?
- Is your code easy to understand and well-abstracted? Do you apply programming principles in your work? Approach the problem as though this code would be productionized and that you and your team would have to maintain it long-term.
- Try not to hack it together.
- You may be inclined to spend more time building specific areas of the app, such as the UI or your object model, depending on what you deem the most important.
- Make thoughtful trade-offs as those you likely do as part of your job today.
- Communicate those decisions to us in the write-up (or inline, as comments) to help us understand your thought process.
- Use frameworks and libraries that you know. Don't feel like you need to learn something new to build this.
- Showcase your existing skill set.
- If you are familiar with git, please use it to track your progress with useful commit messages. The evolution of your codebase can help us get valuable insight into how you approached the problem.
- Plan to spend up to 3 hours working on this. If you finish and have remaining time, you are welcome to make creative improvements to your app. Please document what you changed.
- If you require significantly more than 3 hours, please provide that feedback so that we can better calibrate the requirements.

---

## Write-Up (REQUIRED)

Spend a few minutes to submit a write-up based on these questions, alongside your code. Do not count this time against your 3 hours.

1. How long did you spend working on the problem? What did you find to be the most difficult part?
2. What trade-offs did you make? What did you choose to spend time on, and what did you choose to ignore or do quickly for the sake of completing the project?
3. If you finished with extra time, what improvements did you make that go above and beyond the requirements?

---

## Yelp API Notes

- **API Endpoint**: `https://api.yelp.com/v3/businesses/search`
- **API Spec**: https://www.yelp.com/developers/documentation/v3/business_search
- **Auth header (provided by Fini for this take-home)**:
  ```
  Authorization: Bearer <token redacted — see the assignment doc>
  ```
  The actual token is kept out of this public repo: it lives in `RestaurantViewer/Services/Secrets.swift`, which is gitignored. See `Secrets.example.swift`.
