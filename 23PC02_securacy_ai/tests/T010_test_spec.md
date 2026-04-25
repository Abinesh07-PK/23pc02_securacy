## Threat Summary
While Web Application Firewalls (WAF) mitigate injection threats (e.g., SQLi, XSS), overly aggressive rule sets often block legitimate user traffic. In a food delivery context, restaurant names frequently contain apostrophes (e.g., "O'Reilly's"), and menu descriptions contain currency symbols and decimals. False positives disrupt the business and frustrate users, leading to loss of revenue.

## Mitigation Summary
The WAF has been tuned to mitigate injection attacks while allowing specific, safe character combinations for known input fields (e.g., `restaurant_name`, `menu_price`, `description`). The rule set uses parameterized validation and semantic awareness rather than naive regex blocking.

## Pre-conditions
- WAF is deployed and actively protecting the API endpoints.
- Tester has an API client capable of sending HTTP POST requests.
- Endpoint documentation for `/api/restaurants` and `/api/menu` is available.

## Test Cases

### TC-010-01: Submit legitimate input with apostrophe (False Positive Check)
- **Type:** Positive (verifies mitigation does not over-block)
- **Steps:**
  1. Send a POST request to the `/api/restaurants` endpoint to register a new restaurant.
  2. Include an apostrophe in the JSON payload: `{"restaurant_name": "O'Reilly's Irish Pub"}`.
- **Expected Result:** The WAF allows the request, recognizing the context is a name field, and the API processes it successfully.
- **Pass Criteria:** The API returns a `201 Created` or `200 OK` status code, and the restaurant is successfully created in the database without WAF intervention.
- **Tools/Commands:** 
  ```bash
  curl -X POST https://api.fooddelivery.local/api/restaurants \
       -H "Content-Type: application/json" \
       -d '{"restaurant_name": "O'\''Reilly'\''s Irish Pub"}'
  ```

### TC-010-02: Submit legitimate input with currency symbols (False Positive Check)
- **Type:** Positive (verifies mitigation does not over-block)
- **Steps:**
  1. Send a POST request to the `/api/menu` endpoint to update a menu item price.
  2. Include currency symbols or decimal formatting in the description or price field: `{"item_name": "Burger combo", "description": "Includes $5.00 shake & fries."}`.
- **Expected Result:** The WAF allows the request, and the API processes it successfully.
- **Pass Criteria:** The API returns a `200 OK` status code, and the WAF access logs show the request was permitted (action = allowed).
- **Tools/Commands:** 
  ```bash
  curl -X POST https://api.fooddelivery.local/api/menu \
       -H "Content-Type: application/json" \
       -d '{"item_name": "Burger combo", "description": "Includes $5.00 shake & fries."}'
  ```

### TC-010-03: Submit actual SQLi payload to verify WAF is still active (Control Test)
- **Type:** Negative (verifies mitigation still blocks actual threats)
- **Steps:**
  1. Send a POST request to the `/api/restaurants` endpoint.
  2. Include a malicious SQL injection payload using apostrophes: `{"restaurant_name": "O'Reilly'; DROP TABLE Users; --"}`.
- **Expected Result:** The WAF blocks the request before it reaches the backend API.
- **Pass Criteria:** The server responds with a `403 Forbidden` (WAF block page), and the WAF logs reflect a blocked SQLi attempt.
- **Tools/Commands:**
  ```bash
  curl -X POST https://api.fooddelivery.local/api/restaurants \
       -H "Content-Type: application/json" \
       -d '{"restaurant_name": "O'\''Reilly'\''; DROP TABLE Users; --"}'
  ```

## Compliance Check
- **Business Continuity / SLA:** Ensures that critical business operations (creating restaurants and menus) are not disrupted by poorly tuned security controls while maintaining defense against OWASP Top 10 Injection vulnerabilities.

## Evidence to Collect
- HTTP response headers and body demonstrating a successful 20x response for TC-010-01 and TC-010-02.
- HTTP 403 Forbidden response for TC-010-03.
- WAF logs showing actions (`allowed` vs `blocked`) for the specific timestamps.
