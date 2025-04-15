# Whop Test - Leaderboard

This is a [T3 Stack](https://create.t3.gg/) project bootstrapped with `create-t3-app`.

- [Next.js](https://nextjs.org)
- [Drizzle](https://orm.drizzle.team)
- [Tailwind CSS](https://tailwindcss.com)
- [tRPC](https://trpc.io)

## Prompt:

### Part 1:

```
You are building an API to transfer money.
Core Requirements
API Endpoints
1. POST /api/pay
Records a payment from the authenticated user to another user.

Request:

Header: x-user-id - Identifier of the authenticated user making the payment
Body (JSON):
{
  "recipient_id": integer,
  "amount": integer,  // The amount in cents, so $1.04 = 104
}
Response:

Status Code: 2XX on success
Appropriate error responses for invalid requests
2. GET /api/balance
Returns the current balance for the authenticated user.

Request:

Header: x-user-id - Identifier of the authenticated user making the payment
- Response (JSON):

{
  "amount": integer,  // The amount in cents, so $1.04 = 104.
}
Technical Requirements
Build a RESTful HTTP API
Use MySQL for your DB
Choose any backend programming language and framework you prefer
Implement proper error handling
Create a working local development environment
Assume we're only working with USD
Do not allow users balances to go negative.
Run the seed script to test.
IMPORTANT: User ID 1 is a special account that can have a negative balance. This account is used by the seed script to initially fund other accounts. Your implementation should bypass negative balance validation specifically for this user ID.
Balance Calculation
Example: If user 2 pays user 3 $20 (2000 cents), user 2's balance decreases by 2000 cents and user 3's balance increases by 2000 cents.

Interview Preparation
Your solution must be fully functional on your local machine
During the interview, you'll be asked to run the "seed" script that will generate test data by calling your API. You can find this seed script here (TODO).
The seed script is available here. Run it against your local server.
We will be implementing a new feature together during the interview
Be prepared to explain your design decisions and walk through your code
Note on Authentication
For simplicity, authentication is handled via the x-user-id header. Your API should use this header to identify the current user.
```

### Part 2:

```
We want to add a leaderboard endpoint to your API.

This endpoint returns a list of 10 users, and their associated balance, (ordered and ranked) around the current user id.

Balance = each user's respective balance (as returned by the /api/balance endpoint Rank = each user's respective leaderboard rank. Starting at 1 for the user with the highest balance. Users with the same balance have the same rank.

Here's an example:

> GET /api/leaderboard
> Host:
> x-user-id: 11111

< HTTP/1.1 200
< content-type: application/json
{
    "leaderboard": [
        { "user_id": 54352, "balance": 2314, "rank": 673 },
        { "user_id": 66532, "balance": 2310, "rank": 674 },
        { "user_id": 98432, "balance": 2310, "rank": 674 },
        { "user_id": 10578, "balance": 2287, "rank": 675 },
        { "user_id": 11111, "balance": 2287, "rank": 675 },
        { "user_id": 24068, "balance": 2287, "rank": 675 },
        { "user_id": 23751, "balance": 2286, "rank": 676 },
        { "user_id": 56812, "balance": 2254, "rank": 677 },
        { "user_id": 14356, "balance": 2254, "rank": 677 },
        { "user_id": 41321, "balance": 2103, "rank": 678 }
    ]
}
```
