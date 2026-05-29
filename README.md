# PinPay

PinPay is an AI-powered financial orchestration agent built for the autonomous economy.
It gives AI agents secure financial identities, policy-gated spending controls, and
smart-escrow wallets - so autonomous systems can transact with each other safely,
without human sign-off on every step.

Built on the Anthropic API, PinPay uses Claude as its intelligence layer to evaluate
every transaction request, enforce spending policies, detect fraud signals, and return
structured decisions in real time.

---

## What It Does

PinPay sits between an AI agent and a payment action. Before any funds move, PinPay runs
the request through a policy engine that checks identity, scope, amount, and delivery
conditions. If everything clears, funds go into smart-escrow and release only when
delivery is confirmed. If anything fails, PinPay denies, flags, or claws back automatically.

---

## Core Concepts

**Financial Identity**
Every agent that interacts with PinPay has a registered identity with a Trust Tier,
a spending ceiling, and an active policy set. The tier controls what the agent can do.

**Trust Tiers**
- UNTRUSTED: no direct spend, all requests go to human review.
- PROVISIONAL: micro-transactions under $5, escrow only.
- VERIFIED: full access up to spending ceiling across approved vendor categories.
- ELEVATED: can trigger multi-step payment chains and delegate to child agents.

**The Policy Engine**
Every transaction must match an active policy covering five fields: resource type,
vendor scope, amount envelope, time window, and delivery condition. A missing field
stops the transaction and returns a Policy Gap Report.

**The Grab**
The act of an agent requesting and pulling funds for a specific task. PinPay runs a
7-step sequence on every Grab: identity check, policy match, amount scope, escrow lock,
time window start, delivery confirmation, and audit entry.

**Smart-Escrow**
Funds are held in escrow during an active task. They release to the vendor on confirmed
delivery or clawback to the agent on failure or timeout.

**Clawback**
If a delivery condition is not met within the time window, PinPay reverses the transaction
automatically and logs it as a Delivery Failure.

**Fraud Signals**
PinPay monitors for five patterns in real time:
- Velocity Spike: 3+ Grabs in 60 seconds.
- Scope Creep: vendor category outside the approved set.
- Amount Inflation: requests consistently above task-minimum.
- Identity Drift: behavior inconsistent with prior sessions.
- Orphaned Escrow: escrow open past its time window with no delivery signal.

---

## Features

- Agent Identity Panel with Trust Tier badge and policy display
- Transaction Console to initiate and evaluate Grab requests via Claude
- Escrow Monitor with live countdowns, delivery confirmation, and auto-clawback
- Audit Log with color-coded outcomes and reason codes
- Fraud Signal Monitor tracking active signals for the session

---

## Tech Stack

- React (hooks only, no external state libraries)
- Anthropic API (claude-sonnet-4-20250514)
- Client-side escrow countdowns via setInterval
- In-session state only, no external database

---

## How to Use

1. Register an Agent ID in the Identity Panel and set a Trust Tier.
2. Open the Transaction Console and fill in the Grab fields:
   - Resource Type
   - Vendor
   - Requested Amount
   - Delivery Window (ms)
   - Delivery Condition
3. Submit the request. PinPay sends it to Claude with the full policy engine context.
4. The response panel shows Claude's decision and reasoning.
5. If approved, the escrow opens and the countdown begins in the Escrow Monitor.
6. Click "Confirm Delivery" to settle the escrow, or let the countdown expire to trigger
   a clawback.
7. Every outcome writes to the Audit Log automatically.
8. Check the Fraud Signal Monitor for any patterns flagged during the session.

---

## API Response Structure

Every PinPay decision from Claude returns a structured JSON block used to drive
the UI state:

{
  "status": "APPROVED" | "DENIED" | "ESCALATED" | "CLAWBACK",
  "amount_authorized": number or null,
  "policy_matched": string or null,
  "escrow_window_ms": number or null,
  "fraud_signals": [],
  "reason_code": string,
  "overage_flag": boolean
}

---

## Escalation Conditions

PinPay escalates to the human principal when:
- A transaction exceeds the agent's spending ceiling.
- A Trust Tier upgrade is requested.
- A new vendor category needs to be added to a policy.
- Three or more fraud signals have fired for the same agent in one session.
- A payment chain involves more than four hops.

---

## Project Status

This is a working prototype built for demonstration and development purposes.
Escrow state and audit logs are held in React state and reset on page refresh.
Production use would require a persistent backend, real payment rails integration,
and a formal identity verification layer.

---

## License

MIT
