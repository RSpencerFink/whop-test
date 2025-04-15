# Whop Test - Leaderboard

This is a [T3 Stack](https://create.t3.gg/) project bootstrapped with `create-t3-app`.

- [Next.js](https://nextjs.org)
- [NextAuth.js](https://next-auth.js.org)
- [Prisma](https://prisma.io)
- [Drizzle](https://orm.drizzle.team)
- [Tailwind CSS](https://tailwindcss.com)
- [tRPC](https://trpc.io)

## Prompt:

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
