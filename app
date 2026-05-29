
import React, { useState, useEffect } from "react";
import React, { useState, useEffect, useCallback } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
const queryClient = new QueryClient();
// Types
// ─── Types ────────────────────────────────────────────────────────────────────
type TrustTier = "UNTRUSTED" | "PROVISIONAL" | "VERIFIED" | "ELEVATED";
type Agent = {
  id: string;
  tier: TrustTier;
  ceiling: number;
  policy: string;
};
type Escrow = {
  id: string;
  agentId: string;
-1
+1
  status: "OPEN" | "DELIVERY FAILURE" | "SETTLED";
};
type AuditLog = {
type AuditEntry = {
  id: string;
  timestamp: string;
  agentId: string;
-0
+129
  reason: string;
  action: string;
};
type TxPayload = {
  agentId: string;
  trustTier: string;
  resourceType: string;
  vendor: string;
  requestedAmount: number;
  deliveryWindowMs: number;
  deliveryCondition: string;
  spendingCeiling?: number;
  policySet?: string;
};
type SimJob = {
  agent: Agent;
  resourceType: string;
  vendor: string;
  requestedAmount: number;
  deliveryWindowMs: number;
  deliveryCondition: string;
  label: string;
};
type SimScenario = {
  id: string;
  name: string;
  description: string;
  targetSignals: string[];
  agents: Agent[];
  jobs: SimJob[];
};
type SimState = {
  running: boolean;
  scenarioId: string | null;
  completed: number;
  total: number;
  currentLabel: string;
  log: { label: string; outcome: string; agentId: string }[];
};
// ─── Simulation Scenarios ────────────────────────────────────────────────────
const SCENARIOS: SimScenario[] = [
  {
    id: "velocity",
    name: "VELOCITY STRESS",
    description: "Fires 4 rapid grabs from the same agent to trigger Velocity Spike detection.",
    targetSignals: ["Velocity Spike"],
    agents: [
      { id: "ALPHA-7", tier: "VERIFIED", ceiling: 10000, policy: "STANDARD_V1" },
    ],
    jobs: [
      { agent: { id: "ALPHA-7", tier: "VERIFIED", ceiling: 10000, policy: "STANDARD_V1" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 2.5, deliveryWindowMs: 8000, deliveryCondition: "200_OK", label: "ALPHA-7 :: Grab #1" },
      { agent: { id: "ALPHA-7", tier: "VERIFIED", ceiling: 10000, policy: "STANDARD_V1" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 2.5, deliveryWindowMs: 8000, deliveryCondition: "200_OK", label: "ALPHA-7 :: Grab #2" },
      { agent: { id: "ALPHA-7", tier: "VERIFIED", ceiling: 10000, policy: "STANDARD_V1" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 2.5, deliveryWindowMs: 8000, deliveryCondition: "200_OK", label: "ALPHA-7 :: Grab #3" },
      { agent: { id: "ALPHA-7", tier: "VERIFIED", ceiling: 10000, policy: "STANDARD_V1" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 2.5, deliveryWindowMs: 8000, deliveryCondition: "200_OK", label: "ALPHA-7 :: Grab #4 [SPIKE]" },
    ],
  },
  {
    id: "scope_creep",
    name: "SCOPE CREEP PROBE",
    description: "Agents attempt transactions on vendors outside their approved categories.",
    targetSignals: ["Scope Creep"],
    agents: [
      { id: "BETA-3", tier: "PROVISIONAL", ceiling: 500, policy: "MICRO_TXN_ONLY" },
      { id: "GAMMA-12", tier: "VERIFIED", ceiling: 5000, policy: "COMPUTE_ONLY" },
    ],
    jobs: [
      { agent: { id: "BETA-3", tier: "PROVISIONAL", ceiling: 500, policy: "MICRO_TXN_ONLY" }, resourceType: "REAL_ESTATE", vendor: "ZILLOW_API", requestedAmount: 450, deliveryWindowMs: 15000, deliveryCondition: "LISTING_CONFIRMED", label: "BETA-3 :: Real estate grab [SCOPE]" },
      { agent: { id: "GAMMA-12", tier: "VERIFIED", ceiling: 5000, policy: "COMPUTE_ONLY" }, resourceType: "FINANCIAL_DATA", vendor: "BLOOMBERG_TERMINAL", requestedAmount: 800, deliveryWindowMs: 10000, deliveryCondition: "DATA_STREAM_OPEN", label: "GAMMA-12 :: Finance data [SCOPE]" },
      { agent: { id: "GAMMA-12", tier: "VERIFIED", ceiling: 5000, policy: "COMPUTE_ONLY" }, resourceType: "API_COMPUTE", vendor: "ANTHROPIC", requestedAmount: 12, deliveryWindowMs: 5000, deliveryCondition: "200_OK", label: "GAMMA-12 :: Legitimate grab [PASS]" },
    ],
  },
  {
    id: "inflation",
    name: "AMOUNT INFLATION SWEEP",
    description: "An agent consistently requests amounts well above task-minimum, triggering inflation flags.",
    targetSignals: ["Amount Inflation"],
    agents: [
      { id: "DELTA-9", tier: "ELEVATED", ceiling: 100000, policy: "ELEVATED_OPS_V3" },
    ],
    jobs: [
      { agent: { id: "DELTA-9", tier: "ELEVATED", ceiling: 100000, policy: "ELEVATED_OPS_V3" }, resourceType: "CLOUD_STORAGE", vendor: "AWS_S3", requestedAmount: 500, deliveryWindowMs: 20000, deliveryCondition: "WRITE_ACK", label: "DELTA-9 :: Storage x500 [INFLATED]" },
      { agent: { id: "DELTA-9", tier: "ELEVATED", ceiling: 100000, policy: "ELEVATED_OPS_V3" }, resourceType: "CLOUD_STORAGE", vendor: "AWS_S3", requestedAmount: 480, deliveryWindowMs: 20000, deliveryCondition: "WRITE_ACK", label: "DELTA-9 :: Storage x480 [INFLATED]" },
      { agent: { id: "DELTA-9", tier: "ELEVATED", ceiling: 100000, policy: "ELEVATED_OPS_V3" }, resourceType: "CLOUD_STORAGE", vendor: "AWS_S3", requestedAmount: 510, deliveryWindowMs: 20000, deliveryCondition: "WRITE_ACK", label: "DELTA-9 :: Storage x510 [INFLATED]" },
    ],
  },
  {
    id: "swarm",
    name: "MULTI-AGENT SWARM",
    description: "4 agents across all trust tiers execute simultaneously — covers full tier validation coverage.",
    targetSignals: ["Velocity Spike", "Scope Creep", "Identity Drift"],
    agents: [
      { id: "ZETA-0", tier: "UNTRUSTED", ceiling: 0, policy: "QUARANTINE" },
      { id: "ETA-4", tier: "PROVISIONAL", ceiling: 200, policy: "MICRO_TXN_ONLY" },
      { id: "THETA-6", tier: "VERIFIED", ceiling: 8000, policy: "STANDARD_V2" },
      { id: "IOTA-1", tier: "ELEVATED", ceiling: 75000, policy: "ELEVATED_OPS_V3" },
    ],
    jobs: [
      { agent: { id: "ZETA-0", tier: "UNTRUSTED", ceiling: 0, policy: "QUARANTINE" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 1.0, deliveryWindowMs: 5000, deliveryCondition: "200_OK", label: "ZETA-0 [UNTRUSTED] :: Grab attempt" },
      { agent: { id: "ETA-4", tier: "PROVISIONAL", ceiling: 200, policy: "MICRO_TXN_ONLY" }, resourceType: "API_COMPUTE", vendor: "ANTHROPIC", requestedAmount: 3.5, deliveryWindowMs: 6000, deliveryCondition: "200_OK", label: "ETA-4 [PROVISIONAL] :: Micro grab" },
      { agent: { id: "THETA-6", tier: "VERIFIED", ceiling: 8000, policy: "STANDARD_V2" }, resourceType: "VECTOR_DB", vendor: "PINECONE", requestedAmount: 45, deliveryWindowMs: 10000, deliveryCondition: "INDEX_READY", label: "THETA-6 [VERIFIED] :: Vector DB" },
      { agent: { id: "IOTA-1", tier: "ELEVATED", ceiling: 75000, policy: "ELEVATED_OPS_V3" }, resourceType: "ML_TRAINING", vendor: "RUNPOD", requestedAmount: 320, deliveryWindowMs: 60000, deliveryCondition: "JOB_COMPLETE", label: "IOTA-1 [ELEVATED] :: ML training run" },
      { agent: { id: "THETA-6", tier: "VERIFIED", ceiling: 8000, policy: "STANDARD_V2" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 12, deliveryWindowMs: 5000, deliveryCondition: "200_OK", label: "THETA-6 [VERIFIED] :: Compute grab" },
      { agent: { id: "ZETA-0", tier: "UNTRUSTED", ceiling: 0, policy: "QUARANTINE" }, resourceType: "FINANCIAL_DATA", vendor: "STRIPE_CONNECT", requestedAmount: 99, deliveryWindowMs: 5000, deliveryCondition: "PAYMENT_INTENT_CREATED", label: "ZETA-0 [UNTRUSTED] :: Finance [BLOCKED]" },
    ],
  },
  {
    id: "breach",
    name: "FULL BREACH SIM",
    description: "All five fraud patterns triggered in sequence — the worst-case multi-vector attack scenario.",
    targetSignals: ["Velocity Spike", "Scope Creep", "Amount Inflation", "Identity Drift", "Orphaned Escrow"],
    agents: [
      { id: "ROGUE-X", tier: "VERIFIED", ceiling: 50000, policy: "STANDARD_V2" },
    ],
    jobs: [
      { agent: { id: "ROGUE-X", tier: "VERIFIED", ceiling: 50000, policy: "STANDARD_V2" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 5, deliveryWindowMs: 30000, deliveryCondition: "200_OK", label: "ROGUE-X :: V1 rapid burst" },
      { agent: { id: "ROGUE-X", tier: "VERIFIED", ceiling: 50000, policy: "STANDARD_V2" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 5, deliveryWindowMs: 30000, deliveryCondition: "200_OK", label: "ROGUE-X :: V2 rapid burst" },
      { agent: { id: "ROGUE-X", tier: "VERIFIED", ceiling: 50000, policy: "STANDARD_V2" }, resourceType: "WEAPONS_DATA", vendor: "DARK_MARKETPLACE", requestedAmount: 5, deliveryWindowMs: 3000, deliveryCondition: "RECEIPT", label: "ROGUE-X :: Scope violation [BREACH]" },
      { agent: { id: "ROGUE-X", tier: "VERIFIED", ceiling: 50000, policy: "STANDARD_V2" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 49000, deliveryWindowMs: 30000, deliveryCondition: "200_OK", label: "ROGUE-X :: Ceiling breach attempt" },
      { agent: { id: "ROGUE-X", tier: "VERIFIED", ceiling: 50000, policy: "STANDARD_V2" }, resourceType: "API_COMPUTE", vendor: "OPENAI", requestedAmount: 5, deliveryWindowMs: 1000, deliveryCondition: "200_OK", label: "ROGUE-X :: Orphan escrow trap" },
    ],
  },
];
// ─── Helpers ──────────────────────────────────────────────────────────────────
const uid = () => Math.random().toString(36).substring(2, 9);
const getStatusGlow = (status: string) => {
  switch (status) {
-29
+29
  }
};
const Badge = ({ children, status }: { children: React.ReactNode; status: string }) => {
  return (
    <span className={`inline-flex items-center px-2 py-0.5 text-xs font-mono font-bold uppercase tracking-wider border ${getStatusGlow(status)}`}>
      {children}
    </span>
  );
};
const Badge = ({ children, status }: { children: React.ReactNode; status: string }) => (
  <span className={`inline-flex items-center px-2 py-0.5 text-xs font-mono font-bold uppercase tracking-wider border ${getStatusGlow(status)}`}>
    {children}
  </span>
);
// ─── App ──────────────────────────────────────────────────────────────────────
export default function App() {
  const [agentId, setAgentId] = useState("");
  const [activeAgent, setActiveAgent] = useState<{ id: string; tier: string; ceiling: number; policy: string } | null>(null);
  // Agent
  const [agentIdInput, setAgentIdInput] = useState("");
  const [activeAgent, setActiveAgent] = useState<Agent | null>(null);
  // Shared state
  const [escrows, setEscrows] = useState<Escrow[]>([]);
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [logs, setLogs] = useState<AuditEntry[]>([]);
  const [signals, setSignals] = useState<FraudSignal[]>([]);
  // Transaction form state
  // Manual TX console
  const [txForm, setTxForm] = useState({
    resourceType: "",
    vendor: "",
    requestedAmount: "",
    deliveryWindowMs: "",
    deliveryCondition: "",
    resourceType: "", vendor: "", requestedAmount: "",
    deliveryWindowMs: "", deliveryCondition: "",
  });
  const [txStream, setTxStream] = useState("");
  const [txProcessing, setTxProcessing] = useState(false);
  const [txError, setTxError] = useState("");
  const [txResultStatus, setTxResultStatus] = useState("");
  const handleRegisterAgent = (e: React.FormEvent) => {
    e.preventDefault();
    if (!agentId.trim()) return;
    setActiveAgent({
      id: agentId,
      tier: "VERIFIED",
      ceiling: 50000,
      policy: "STRICT_AUDIT_V2",
    });
  };
  // Simulation
  const [simOpen, setSimOpen] = useState(false);
  const [simSelected, setSimSelected] = useState<string | null>(null);
  const [simState, setSimState] = useState<SimState>({
    running: false, scenarioId: null, completed: 0, total: 0, currentLabel: "", log: [],
  });
  const simAbortRef = React.useRef(false);
  // ── Escrow countdown ──────────────────────────────────────────────────────
  useEffect(() => {
    const interval = setInterval(() => {
      setEscrows(prev => pr...
[truncated]
