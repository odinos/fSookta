# Sookta App Store Connect Age Rating Answers

Updated: 2026-05-30

Use these answers for the App Store Connect Age Ratings questionnaire for Sookta, based on the current app behavior: ergonomic risk education/research support, local camera/gallery capture, local history/export, TTS, and offline ML. The app is not a game, does not contain social features, gambling, user-generated public content, web browsing, or medical diagnosis.

Apple determines the rating from the questionnaire. Choose a higher override only if the project terms, IRB/research protocol, or client policy explicitly requires adult-only use.

Apple reference:
- https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/

## In-App Controls And Capabilities

| Question / Category | Recommended Answer | Notes |
| --- | --- | --- |
| Parental Controls | No / Not included | No parental-control feature. |
| Age Assurance | No / Not included | No age verification flow. |
| Advertising | No | No ads. |
| User-Generated Content | No | Photos/profile/history stay local and are not published to other users. |
| Messaging and Chat | No | No chat or messaging. |
| Unrestricted Web Access | No | No open browser or unrestricted web content. |

## Medical Or Wellness

| Question / Category | Recommended Answer | Notes |
| --- | --- | --- |
| Health and Wellness Topics | Frequent | The app’s main purpose is ergonomic risk awareness and work posture education. |
| Medical or Treatment Information | None | The app does not diagnose, treat, prescribe, or provide clinical injury guidance. If Apple’s wording treats ergonomic risk recommendations as treatment-related, choose Infrequent instead of None. |

## Violence

| Question / Category | Recommended Answer |
| --- | --- |
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Guns or Other Weapons | None |

## Mature Themes

| Question / Category | Recommended Answer |
| --- | --- |
| Profanity or Crude Humor | None |
| Horror or Fear Themes | None |
| Alcohol, Tobacco, or Drug Use or References | None |

## Sexuality Or Nudity

| Question / Category | Recommended Answer |
| --- | --- |
| Mature or Suggestive Themes | None |
| Sexual Content or Nudity | None |

## Chance-Based Activities

| Question / Category | Recommended Answer |
| --- | --- |
| Contests | None |
| Simulated Gambling | None |
| Gambling | No |
| Loot Boxes | No |

## Age Categories And Override

| Question / Category | Recommended Answer | Notes |
| --- | --- | --- |
| Made for Kids | Not Applicable | Sookta is not designed for the Kids category. |
| Override to Higher Age Rating | Not Applicable by default | Use only if the research protocol or terms require a higher minimum age. |
| Adult-only research participant requirement | Optional: Override to 18+ | Select this only if client/research policy says the app must be used only by adults. |
| Age Suitability URL | Optional | Leave blank unless a public age-suitability or research-use page is available. |

## Expected Outcome

With the recommended answers, the calculated Apple rating should remain low to moderate because the app has health/wellness education content but no objectionable content. If App Store Connect asks whether ergonomic guidance counts as medical/treatment information, use the conservative answer `Infrequent` for that specific item and keep the app description/review notes clear that Sookta is not a medical diagnosis or treatment tool.

## Review Note To Keep Consistent

Sookta is an ergonomic risk communication and research-support app for Thai coffee-farming workflows. It uses camera/photo access only to capture posture images for on-device assessment. Results are educational/research support outputs, not medical diagnosis, treatment, injury confirmation, or exact individual cost calculation.
