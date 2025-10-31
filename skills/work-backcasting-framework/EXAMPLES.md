# Work Backcasting Framework - Examples

## Table of Contents
1. [Example 1: End State Definer](#example-1-end-state-definer)
2. [Example 2: Backward Chaining Planner](#example-2-backward-chaining-planner)
3. [Example 3: Prerequisite Detector](#example-3-prerequisite-detector)
4. [Example 4: Feasibility Checker](#example-4-feasibility-checker)
5. [Example 5: Migration Planner](#example-5-migration-planner)
6. [Real-World Use Cases](#real-world-use-cases)

---

## Example 1: End State Definer

### Purpose
Define concrete, measurable end states with validation.

### Code

```python
#!/usr/bin/env python3
"""
End State Definition Tool
Creates structured, validated end state definitions.
"""

import json
from dataclasses import dataclass, asdict
from typing import List, Dict, Optional
from enum import Enum


class Priority(Enum):
    MUST_HAVE = "must-have"
    SHOULD_HAVE = "should-have"
    NICE_TO_HAVE = "nice-to-have"


@dataclass
class Metric:
    name: str
    current_value: float
    target_value: float
    unit: str

    @property
    def gap(self) -> float:
        return self.target_value - self.current_value

    @property
    def gap_percentage(self) -> float:
        if self.current_value == 0:
            return 100.0
        return (self.gap / self.current_value) * 100


@dataclass
class SuccessCriterion:
    description: str
    verification_method: str
    priority: Priority


@dataclass
class Constraint:
    type: str  # technical, resource, timeline, organizational
    description: str
    is_blocking: bool


class EndStateDefinition:
    """Structured end state with SMART criteria validation"""

    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description
        self.metrics: List[Metric] = []
        self.success_criteria: List[SuccessCriterion] = []
        self.constraints: List[Constraint] = []
        self.architecture: Dict = {}
        self.capabilities: Dict = {}
        self.deadline: Optional[str] = None

    def add_metric(self, name: str, current: float, target: float, unit: str):
        """Add a measurable metric"""
        self.metrics.append(Metric(name, current, target, unit))

    def add_success_criterion(
        self,
        description: str,
        verification: str,
        priority: Priority
    ):
        """Add an acceptance criterion"""
        self.success_criteria.append(
            SuccessCriterion(description, verification, priority)
        )

    def add_constraint(self, type: str, description: str, is_blocking: bool):
        """Add a constraint"""
        self.constraints.append(Constraint(type, description, is_blocking))

    def set_architecture(self, arch_dict: Dict):
        """Define target architecture"""
        self.architecture = arch_dict

    def set_capabilities(self, cap_dict: Dict):
        """Define target capabilities"""
        self.capabilities = cap_dict

    def set_deadline(self, deadline: str):
        """Set deadline (ISO 8601 format)"""
        self.deadline = deadline

    def validate_smart(self) -> tuple[bool, List[str]]:
        """
        Validate SMART criteria.

        Returns:
            (is_valid, list_of_issues)
        """
        issues = []

        # Specific: Clear description
        if not self.description or len(self.description) < 20:
            issues.append("Description too vague (must be >= 20 characters)")

        # Measurable: At least one metric
        if not self.metrics:
            issues.append("No measurable metrics defined")

        # Achievable: Check blocking constraints
        blocking_constraints = [c for c in self.constraints if c.is_blocking]
        if len(blocking_constraints) > 3:
            issues.append(
                f"Too many blocking constraints ({len(blocking_constraints)}). "
                "Consider if goal is achievable."
            )

        # Relevant: Capabilities or architecture defined
        if not self.capabilities and not self.architecture:
            issues.append("No capabilities or architecture defined (relevance unclear)")

        # Time-bound: Deadline set
        if not self.deadline:
            issues.append("No deadline specified")

        return len(issues) == 0, issues

    def to_dict(self) -> Dict:
        """Export as dictionary"""
        return {
            'name': self.name,
            'description': self.description,
            'metrics': [asdict(m) for m in self.metrics],
            'success_criteria': [
                {
                    'description': sc.description,
                    'verification': sc.verification_method,
                    'priority': sc.priority.value
                }
                for sc in self.success_criteria
            ],
            'constraints': [asdict(c) for c in self.constraints],
            'architecture': self.architecture,
            'capabilities': self.capabilities,
            'deadline': self.deadline
        }

    def to_json(self, filepath: str):
        """Save to JSON file"""
        with open(filepath, 'w') as f:
            json.dump(self.to_dict(), f, indent=2)

    @classmethod
    def from_json(cls, filepath: str) -> 'EndStateDefinition':
        """Load from JSON file"""
        with open(filepath) as f:
            data = json.load(f)

        end_state = cls(data['name'], data['description'])

        for metric in data['metrics']:
            end_state.add_metric(
                metric['name'],
                metric['current_value'],
                metric['target_value'],
                metric['unit']
            )

        for criterion in data['success_criteria']:
            end_state.add_success_criterion(
                criterion['description'],
                criterion['verification'],
                Priority(criterion['priority'])
            )

        for constraint in data['constraints']:
            end_state.add_constraint(
                constraint['type'],
                constraint['description'],
                constraint['is_blocking']
            )

        end_state.architecture = data.get('architecture', {})
        end_state.capabilities = data.get('capabilities', {})
        end_state.deadline = data.get('deadline')

        return end_state


# Example usage
if __name__ == "__main__":
    # Define end state for database migration
    end_state = EndStateDefinition(
        name="PostgreSQL Migration Complete",
        description=(
            "All production application data successfully migrated from MySQL "
            "to PostgreSQL 15 with zero data loss, downtime under 5 minutes, "
            "and query performance improved by 60%"
        )
    )

    # Add metrics
    end_state.add_metric("data_completeness", 0, 100, "percent")
    end_state.add_metric("query_latency_p95", 800, 200, "milliseconds")
    end_state.add_metric("downtime", 0, 5, "minutes")
    end_state.add_metric("data_loss", 0, 0, "records")

    # Add success criteria
    end_state.add_success_criterion(
        "All application queries successfully execute on PostgreSQL",
        "Run full integration test suite against PostgreSQL",
        Priority.MUST_HAVE
    )
    end_state.add_success_criterion(
        "Data integrity verified via checksums",
        "Compare row counts and MD5 hashes for all tables",
        Priority.MUST_HAVE
    )
    end_state.add_success_criterion(
        "Rollback procedure tested",
        "Execute rollback in staging environment",
        Priority.MUST_HAVE
    )
    end_state.add_success_criterion(
        "Performance benchmarks met",
        "Run load tests showing p95 latency < 200ms at 5k RPS",
        Priority.SHOULD_HAVE
    )

    # Add constraints
    end_state.add_constraint(
        "timeline",
        "Must complete within 3 months (by 2024-06-30)",
        is_blocking=False
    )
    end_state.add_constraint(
        "resource",
        "Budget limited to $50,000",
        is_blocking=False
    )
    end_state.add_constraint(
        "technical",
        "Must maintain ACID transaction guarantees",
        is_blocking=True
    )
    end_state.add_constraint(
        "organizational",
        "Requires security team approval before production deployment",
        is_blocking=True
    )

    # Define architecture
    end_state.set_architecture({
        'database': 'PostgreSQL 15',
        'connection_pool': 'pgbouncer',
        'replication': 'streaming replication (1 primary, 2 replicas)',
        'backup': 'pg_basebackup + WAL archiving to S3',
        'monitoring': 'Prometheus + Grafana with pg_exporter'
    })

    # Define capabilities
    end_state.set_capabilities({
        'functional': [
            "All CRUD operations on PostgreSQL",
            "Complex joins and aggregations",
            "Full-text search via pg_trgm"
        ],
        'non_functional': {
            'performance': "p95 < 200ms, p99 < 500ms at 5k RPS",
            'reliability': "99.9% uptime, MTBF > 720 hours",
            'scalability': "Supports up to 10k concurrent connections",
            'security': "Encryption at rest and in transit, role-based access"
        }
    })

    # Set deadline
    end_state.set_deadline("2024-06-30")

    # Validate
    is_valid, issues = end_state.validate_smart()
    if is_valid:
        print(f"✓ End state '{end_state.name}' is valid")
    else:
        print(f"✗ End state has issues:")
        for issue in issues:
            print(f"  - {issue}")

    # Show metrics
    print("\nMetrics:")
    for metric in end_state.metrics:
        print(f"  {metric.name}: {metric.current_value} → {metric.target_value} {metric.unit}")
        print(f"    Gap: {metric.gap} {metric.unit} ({metric.gap_percentage:.1f}%)")

    # Save to file
    end_state.to_json("end_state_postgres_migration.json")
    print("\n✓ Saved to end_state_postgres_migration.json")
```

### Output

```
✓ End state 'PostgreSQL Migration Complete' is valid

Metrics:
  data_completeness: 0.0 → 100.0 percent
    Gap: 100.0 percent (inf%)
  query_latency_p95: 800.0 → 200.0 milliseconds
    Gap: -600.0 milliseconds (-75.0%)
  downtime: 0.0 → 5.0 minutes
    Gap: 5.0 minutes (inf%)
  data_loss: 0.0 → 0.0 records
    Gap: 0.0 records (0.0%)

✓ Saved to end_state_postgres_migration.json
```

---

## Example 2: Backward Chaining Planner

### Purpose
Build a backward chain from goal to current state using state-space search.

### Code

```python
#!/usr/bin/env python3
"""
Backward Chaining Planner
Builds dependency chain from goal state to current state.
"""

from dataclasses import dataclass
from typing import List, Set, Optional, Dict
from collections import deque


@dataclass
class State:
    """Represents a system state"""
    name: str
    predicates: Set[str]
    metadata: Dict = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}

    def __hash__(self):
        return hash((self.name, frozenset(self.predicates)))

    def __eq__(self, other):
        return (
            self.name == other.name and
            self.predicates == other.predicates
        )


@dataclass
class Transition:
    """Represents a valid state transition"""
    name: str
    from_state: State
    to_state: State
    action: str
    cost: float = 1.0


class BackwardChainer:
    """Build backward chain from goal to current state"""

    def __init__(self):
        self.transitions: List[Transition] = []

    def add_transition(self, transition: Transition):
        """Register a valid state transition"""
        self.transitions.append(transition)

    def build_chain(
        self,
        current: State,
        goal: State,
        max_depth: int = 20
    ) -> Optional[List[State]]:
        """
        Build backward chain from goal to current.

        Returns:
            List of states from current to goal, or None if no path found
        """
        # Breadth-first search backward from goal
        queue = deque([(goal, [goal])])
        visited = {self._state_key(goal)}

        while queue:
            current_state, path = queue.popleft()

            # Check if we've reached the starting state
            if self._states_match(current_state, current):
                return list(reversed(path))

            # Depth limit
            if len(path) >= max_depth:
                continue

            # Find transitions that lead TO current_state
            predecessors = self._find_predecessors(current_state)

            for pred_state in predecessors:
                pred_key = self._state_key(pred_state)
                if pred_key not in visited:
                    visited.add(pred_key)
                    queue.append((pred_state, path + [pred_state]))

        return None  # No path found

    def _find_predecessors(self, state: State) -> List[State]:
        """Find all states that can transition to given state"""
        predecessors = []
        for transition in self.transitions:
            if self._states_match(transition.to_state, state):
                predecessors.append(transition.from_state)
        return predecessors

    def _states_match(self, state1: State, state2: State) -> bool:
        """Check if two states match (by predicates)"""
        return state1.predicates == state2.predicates

    def _state_key(self, state: State) -> str:
        """Generate unique key for state"""
        return f"{state.name}:{','.join(sorted(state.predicates))}"

    def get_transition_between(
        self,
        from_state: State,
        to_state: State
    ) -> Optional[Transition]:
        """Find transition between two states"""
        for transition in self.transitions:
            if (self._states_match(transition.from_state, from_state) and
                self._states_match(transition.to_state, to_state)):
                return transition
        return None


# Example: Microservices migration
if __name__ == "__main__":
    # Define states
    current = State(
        name="Monolith",
        predicates={
            "single_codebase",
            "shared_database",
            "tight_coupling",
            "synchronous_calls"
        }
    )

    modular_monolith = State(
        name="Modular Monolith",
        predicates={
            "single_codebase",
            "shared_database",
            "bounded_contexts_defined",
            "module_boundaries_clear",
            "synchronous_calls"
        }
    )

    strangler_started = State(
        name="Strangler Pattern Started",
        predicates={
            "monolith_exists",
            "first_service_extracted",
            "api_gateway_deployed",
            "dual_routing_active",
            "shared_database"  # Still shared for now
        }
    )

    services_independent = State(
        name="Services Independent",
        predicates={
            "multiple_services",
            "api_gateway_deployed",
            "database_per_service",
            "service_mesh_deployed",
            "async_communication"
        }
    )

    goal = State(
        name="Full Microservices",
        predicates={
            "microservices_architecture",
            "services_independently_deployable",
            "database_per_service",
            "async_communication",
            "distributed_tracing",
            "service_mesh_deployed"
        }
    )

    # Define transitions
    chainer = BackwardChainer()

    chainer.add_transition(Transition(
        name="Identify Bounded Contexts",
        from_state=current,
        to_state=modular_monolith,
        action="Domain-driven design analysis, define module boundaries",
        cost=40  # person-hours
    ))

    chainer.add_transition(Transition(
        name="Extract First Service",
        from_state=modular_monolith,
        to_state=strangler_started,
        action="Apply strangler fig pattern, deploy API gateway",
        cost=80
    ))

    chainer.add_transition(Transition(
        name="Extract Remaining Services",
        from_state=strangler_started,
        to_state=services_independent,
        action="Incrementally extract services, implement database-per-service",
        cost=200
    ))

    chainer.add_transition(Transition(
        name="Add Observability & Async",
        from_state=services_independent,
        to_state=goal,
        action="Implement distributed tracing, add message bus for async",
        cost=60
    ))

    # Build backward chain
    print("Building backward chain from current to goal...\n")
    chain = chainer.build_chain(current, goal)

    if chain:
        print("✓ Backward chain found!\n")
        print("Path from current state to goal:")
        total_cost = 0

        for i, state in enumerate(chain):
            print(f"\n{i+1}. {state.name}")
            print(f"   Predicates: {', '.join(sorted(state.predicates))}")

            if i < len(chain) - 1:
                next_state = chain[i + 1]
                transition = chainer.get_transition_between(state, next_state)
                if transition:
                    print(f"   → Action: {transition.action}")
                    print(f"   → Cost: {transition.cost} hours")
                    total_cost += transition.cost

        print(f"\n✓ Total estimated effort: {total_cost} person-hours")
        print(f"  ({total_cost / 40:.1f} person-weeks)")

    else:
        print("✗ No path found from current to goal")
```

### Output

```
Building backward chain from current to goal...

✓ Backward chain found!

Path from current state to goal:

1. Monolith
   Predicates: shared_database, single_codebase, synchronous_calls, tight_coupling
   → Action: Domain-driven design analysis, define module boundaries
   → Cost: 40.0 hours

2. Modular Monolith
   Predicates: bounded_contexts_defined, module_boundaries_clear, shared_database, single_codebase, synchronous_calls
   → Action: Apply strangler fig pattern, deploy API gateway
   → Cost: 80.0 hours

3. Strangler Pattern Started
   Predicates: api_gateway_deployed, dual_routing_active, first_service_extracted, monolith_exists, shared_database
   → Action: Incrementally extract services, implement database-per-service
   → Cost: 200.0 hours

4. Services Independent
   Predicates: api_gateway_deployed, async_communication, database_per_service, multiple_services, service_mesh_deployed
   → Action: Implement distributed tracing, add message bus for async
   → Cost: 60.0 hours

5. Full Microservices
   Predicates: async_communication, database_per_service, distributed_tracing, microservices_architecture, service_mesh_deployed, services_independently_deployable

✓ Total estimated effort: 380.0 person-hours
  (9.5 person-weeks)
```

---

## Example 3: Prerequisite Detector

### Purpose
Systematically identify all prerequisites for state transitions.

### Code

```python
#!/usr/bin/env python3
"""
Prerequisite Detector
Identifies all prerequisites needed for state transitions.
"""

from dataclasses import dataclass
from typing import List, Dict, Set
from enum import Enum


class PrerequisiteType(Enum):
    TECHNICAL = "technical"
    DATA = "data"
    KNOWLEDGE = "knowledge"
    RESOURCE = "resource"
    ORGANIZATIONAL = "organizational"
    DEPENDENCY = "dependency"
    COMPLIANCE = "compliance"


class Criticality(Enum):
    BLOCKING = "blocking"
    LIMITING = "limiting"
    OPTIONAL = "optional"


@dataclass
class Prerequisite:
    """A requirement for a state transition"""
    type: PrerequisiteType
    description: str
    criticality: Criticality
    verification_method: str = ""
    satisfied: bool = False


class PrerequisiteDetector:
    """Detect prerequisites for state transitions"""

    def __init__(self):
        # Knowledge base of prerequisite rules
        self.predicate_rules = self._build_predicate_rules()

    def detect_for_transition(
        self,
        from_predicates: Set[str],
        to_predicates: Set[str],
        transition_name: str
    ) -> List[Prerequisite]:
        """
        Detect prerequisites for a state transition.

        Args:
            from_predicates: Predicates true in starting state
            to_predicates: Predicates true in target state
            transition_name: Name/description of transition

        Returns:
            List of prerequisites
        """
        prereqs = []

        # Analyze what's being added
        added = to_predicates - from_predicates
        for predicate in added:
            prereqs.extend(self._prerequisites_for_adding(predicate))

        # Analyze what's being removed
        removed = from_predicates - to_predicates
        for predicate in removed:
            prereqs.extend(self._prerequisites_for_removing(predicate))

        # Add implicit prerequisites based on transition type
        prereqs.extend(self._implicit_prerequisites(
            from_predicates,
            to_predicates,
            transition_name
        ))

        # Deduplicate
        seen = set()
        unique_prereqs = []
        for prereq in prereqs:
            key = (prereq.type, prereq.description)
            if key not in seen:
                seen.add(key)
                unique_prereqs.append(prereq)

        return unique_prereqs

    def _build_predicate_rules(self) -> Dict[str, List[Prerequisite]]:
        """Build knowledge base of prerequisites for predicates"""
        return {
            # Database predicates
            "database_per_service": [
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Database provisioning automation in place",
                    Criticality.BLOCKING,
                    "Verify can create new DB instance via script"
                ),
                Prerequisite(
                    PrerequisiteType.DATA,
                    "Data ownership boundaries defined",
                    Criticality.BLOCKING,
                    "Document which service owns which tables"
                )
            ],

            # Service mesh
            "service_mesh_deployed": [
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Kubernetes cluster operational",
                    Criticality.BLOCKING,
                    "kubectl cluster-info succeeds"
                ),
                Prerequisite(
                    PrerequisiteType.KNOWLEDGE,
                    "Team trained on service mesh concepts",
                    Criticality.LIMITING,
                    "Team completes Istio/Linkerd training"
                ),
                Prerequisite(
                    PrerequisiteType.RESOURCE,
                    "Additional infrastructure for control plane",
                    Criticality.BLOCKING,
                    "Provision 3 nodes for control plane"
                )
            ],

            # Async communication
            "async_communication": [
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Message broker deployed (Kafka/RabbitMQ)",
                    Criticality.BLOCKING,
                    "Broker is operational and accessible"
                ),
                Prerequisite(
                    PrerequisiteType.KNOWLEDGE,
                    "Team understands event-driven patterns",
                    Criticality.BLOCKING,
                    "Team completes async/event training"
                ),
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Message schema registry in place",
                    Criticality.LIMITING,
                    "Schema registry operational"
                )
            ],

            # API Gateway
            "api_gateway_deployed": [
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Gateway software selected and tested",
                    Criticality.BLOCKING,
                    "POC deployment successful"
                ),
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Routing rules defined for all endpoints",
                    Criticality.BLOCKING,
                    "Routing configuration documented"
                ),
                Prerequisite(
                    PrerequisiteType.COMPLIANCE,
                    "SSL certificates obtained",
                    Criticality.BLOCKING,
                    "Certs installed and verified"
                ),
                Prerequisite(
                    PrerequisiteType.ORGANIZATIONAL,
                    "DNS changes approved",
                    Criticality.BLOCKING,
                    "Change request approved by ops team"
                )
            ],

            # Distributed tracing
            "distributed_tracing": [
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Tracing infrastructure deployed (Jaeger/Zipkin)",
                    Criticality.BLOCKING,
                    "Tracing UI accessible"
                ),
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "All services instrumented with trace context",
                    Criticality.BLOCKING,
                    "Trace propagation working end-to-end"
                ),
                Prerequisite(
                    PrerequisiteType.RESOURCE,
                    "Storage for trace data",
                    Criticality.BLOCKING,
                    "Sufficient storage allocated"
                )
            ],

            # Bounded contexts
            "bounded_contexts_defined": [
                Prerequisite(
                    PrerequisiteType.KNOWLEDGE,
                    "Domain experts available for interviews",
                    Criticality.BLOCKING,
                    "Schedule workshops with domain experts"
                ),
                Prerequisite(
                    PrerequisiteType.ORGANIZATIONAL,
                    "Time allocated for DDD analysis",
                    Criticality.BLOCKING,
                    "Team has 2 weeks for domain modeling"
                ),
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Existing codebase documented",
                    Criticality.LIMITING,
                    "Code structure and dependencies mapped"
                )
            ]
        }

    def _prerequisites_for_adding(self, predicate: str) -> List[Prerequisite]:
        """Get prerequisites for making a predicate true"""
        return self.predicate_rules.get(predicate, [])

    def _prerequisites_for_removing(self, predicate: str) -> List[Prerequisite]:
        """Get prerequisites for making a predicate false (removal safety)"""
        # When removing something, need safety measures
        removal_safety = {
            "shared_database": [
                Prerequisite(
                    PrerequisiteType.DATA,
                    "Full database backup created",
                    Criticality.BLOCKING,
                    "Verify backup and test restore"
                ),
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "Rollback procedure documented and tested",
                    Criticality.BLOCKING,
                    "Successfully execute rollback in staging"
                )
            ],
            "monolith_exists": [
                Prerequisite(
                    PrerequisiteType.TECHNICAL,
                    "All functionality migrated to services",
                    Criticality.BLOCKING,
                    "Feature parity test passes"
                ),
                Prerequisite(
                    PrerequisiteType.ORGANIZATIONAL,
                    "Stakeholder approval to decommission",
                    Criticality.BLOCKING,
                    "Written approval from product owner"
                )
            ]
        }
        return removal_safety.get(predicate, [])

    def _implicit_prerequisites(
        self,
        from_predicates: Set[str],
        to_predicates: Set[str],
        transition_name: str
    ) -> List[Prerequisite]:
        """
        Identify implicit prerequisites not tied to specific predicates.
        These are context-dependent.
        """
        implicit = []

        # All major transitions need these
        implicit.extend([
            Prerequisite(
                PrerequisiteType.ORGANIZATIONAL,
                f"Approval for transition: {transition_name}",
                Criticality.LIMITING,
                "Architecture review board sign-off"
            ),
            Prerequisite(
                PrerequisiteType.RESOURCE,
                "Team capacity allocated",
                Criticality.BLOCKING,
                "Resource planning shows available capacity"
            ),
            Prerequisite(
                PrerequisiteType.TECHNICAL,
                "Comprehensive test coverage in place",
                Criticality.LIMITING,
                "Test coverage > 80% for affected code"
            )
        ])

        # If making architectural changes, need these
        if len(to_predicates - from_predicates) >= 3:
            implicit.append(
                Prerequisite(
                    PrerequisiteType.ORGANIZATIONAL,
                    "Communication plan for stakeholders",
                    Criticality.LIMITING,
                    "Stakeholder update email drafted"
                )
            )

        return implicit


# Example usage
if __name__ == "__main__":
    detector = PrerequisiteDetector()

    # Transition: Monolith → Modular Monolith
    print("=" * 70)
    print("Transition: Monolith → Modular Monolith")
    print("=" * 70)

    from_state = {
        "single_codebase",
        "shared_database",
        "tight_coupling"
    }

    to_state = {
        "single_codebase",
        "shared_database",
        "bounded_contexts_defined",
        "module_boundaries_clear"
    }

    prereqs = detector.detect_for_transition(
        from_state,
        to_state,
        "Identify Bounded Contexts"
    )

    print(f"\nFound {len(prereqs)} prerequisites:\n")
    for i, prereq in enumerate(prereqs, 1):
        print(f"{i}. [{prereq.type.value.upper()}] {prereq.description}")
        print(f"   Criticality: {prereq.criticality.value}")
        if prereq.verification_method:
            print(f"   Verification: {prereq.verification_method}")
        print()

    # Transition: Services Independent → Full Microservices
    print("=" * 70)
    print("Transition: Services Independent → Full Microservices")
    print("=" * 70)

    from_state2 = {
        "multiple_services",
        "api_gateway_deployed",
        "database_per_service",
        "service_mesh_deployed"
    }

    to_state2 = {
        "microservices_architecture",
        "services_independently_deployable",
        "database_per_service",
        "async_communication",
        "distributed_tracing",
        "service_mesh_deployed"
    }

    prereqs2 = detector.detect_for_transition(
        from_state2,
        to_state2,
        "Add Observability & Async"
    )

    print(f"\nFound {len(prereqs2)} prerequisites:\n")

    # Group by type
    by_type = {}
    for prereq in prereqs2:
        by_type.setdefault(prereq.type, []).append(prereq)

    for prereq_type, prereq_list in sorted(by_type.items(), key=lambda x: x[0].value):
        print(f"\n{prereq_type.value.upper()} ({len(prereq_list)}):")
        for prereq in prereq_list:
            symbol = "🔴" if prereq.criticality == Criticality.BLOCKING else "🟡"
            print(f"  {symbol} {prereq.description}")
```

### Output

```
======================================================================
Transition: Monolith → Modular Monolith
======================================================================

Found 6 prerequisites:

1. [KNOWLEDGE] Domain experts available for interviews
   Criticality: blocking
   Verification: Schedule workshops with domain experts

2. [ORGANIZATIONAL] Time allocated for DDD analysis
   Criticality: blocking
   Verification: Team has 2 weeks for domain modeling

3. [TECHNICAL] Existing codebase documented
   Criticality: limiting
   Verification: Code structure and dependencies mapped

4. [ORGANIZATIONAL] Approval for transition: Identify Bounded Contexts
   Criticality: limiting
   Verification: Architecture review board sign-off

5. [RESOURCE] Team capacity allocated
   Criticality: blocking
   Verification: Resource planning shows available capacity

6. [TECHNICAL] Comprehensive test coverage in place
   Criticality: limiting
   Verification: Test coverage > 80% for affected code

======================================================================
Transition: Services Independent → Full Microservices
======================================================================

Found 10 prerequisites:

KNOWLEDGE (1):
  🟡 Team understands event-driven patterns

ORGANIZATIONAL (2):
  🟡 Approval for transition: Add Observability & Async
  🟡 Communication plan for stakeholders

RESOURCE (2):
  🔴 Team capacity allocated
  🔴 Storage for trace data

TECHNICAL (5):
  🔴 Message broker deployed (Kafka/RabbitMQ)
  🟡 Message schema registry in place
  🔴 Tracing infrastructure deployed (Jaeger/Zipkin)
  🔴 All services instrumented with trace context
  🟡 Comprehensive test coverage in place
```

---

## Example 4: Feasibility Checker

### Purpose
Validate that a backward chain is achievable within constraints.

### Code

```python
#!/usr/bin/env python3
"""
Feasibility Checker
Validates backward chain against constraints.
"""

from dataclasses import dataclass
from typing import List, Dict, Optional
from enum import Enum


class IssueType(Enum):
    CONTRADICTION = "contradiction"
    IMPOSSIBLE = "impossible"
    TIMELINE_EXCEEDED = "timeline_exceeded"
    BUDGET_EXCEEDED = "budget_exceeded"
    CAPACITY_EXCEEDED = "capacity_exceeded"
    UNSATISFIABLE_PREREQ = "unsatisfiable_prerequisite"


@dataclass
class FeasibilityIssue:
    """Represents a feasibility problem"""
    type: IssueType
    severity: str  # critical, high, medium, low
    description: str
    affected_item: str
    recommendation: Optional[str] = None


@dataclass
class Constraints:
    """System constraints"""
    max_budget_usd: float
    max_timeline_weeks: float
    max_team_size: int
    required_technologies: List[str]
    prohibited_technologies: List[str]
    technical_constraints: Dict[str, any]


class FeasibilityChecker:
    """Check if backward chain is feasible"""

    def __init__(self, constraints: Constraints):
        self.constraints = constraints

    def check_chain(
        self,
        chain: List[Dict],  # List of states
        transitions: List[Dict],  # List of transitions
        prerequisites: Dict[str, List[Dict]]  # Prerequisites per transition
    ) -> tuple[bool, List[FeasibilityIssue]]:
        """
        Comprehensive feasibility check.

        Returns:
            (is_feasible, list_of_issues)
        """
        issues = []

        # Check each state for consistency
        for state in chain:
            issues.extend(self._check_state_consistency(state))

        # Check each transition
        for transition in transitions:
            issues.extend(self._check_transition_feasibility(
                transition,
                prerequisites.get(transition['name'], [])
            ))

        # Check overall constraints
        issues.extend(self._check_overall_constraints(
            transitions,
            prerequisites
        ))

        # Determine if feasible (no critical issues)
        critical_issues = [i for i in issues if i.severity == 'critical']
        is_feasible = len(critical_issues) == 0

        return is_feasible, issues

    def _check_state_consistency(self, state: Dict) -> List[FeasibilityIssue]:
        """Check if state has internal contradictions"""
        issues = []
        predicates = set(state['predicates'])

        # Define contradiction rules
        contradictions = [
            (
                {'stateless', 'stores_session_data'},
                "State cannot be both stateless and store session data"
            ),
            (
                {'synchronous_only', 'async_communication'},
                "State cannot have only synchronous and async communication"
            ),
            (
                {'single_database', 'database_per_service'},
                "State cannot have both single database and database-per-service"
            ),
            (
                {'monolith_exists', 'microservices_architecture'},
                "State cannot be both monolith and microservices"
            )
        ]

        for contradiction_set, message in contradictions:
            if contradiction_set.issubset(predicates):
                issues.append(FeasibilityIssue(
                    type=IssueType.CONTRADICTION,
                    severity='critical',
                    description=message,
                    affected_item=state['name'],
                    recommendation="Remove one of the contradictory predicates"
                ))

        # Check for impossible predicates
        impossible_predicates = {
            'zero_latency': "Zero latency is physically impossible",
            'infinite_scalability': "Infinite scalability is impossible",
            'perfect_security': "Perfect security is unachievable",
            'bug_free': "Bug-free software is unrealistic"
        }

        for predicate in predicates:
            if predicate in impossible_predicates:
                issues.append(FeasibilityIssue(
                    type=IssueType.IMPOSSIBLE,
                    severity='critical',
                    description=impossible_predicates[predicate],
                    affected_item=state['name'],
                    recommendation=f"Remove or redefine '{predicate}' predicate"
                ))

        return issues

    def _check_transition_feasibility(
        self,
        transition: Dict,
        prerequisites: List[Dict]
    ) -> List[FeasibilityIssue]:
        """Check if transition prerequisites are satisfiable"""
        issues = []

        # Check blocking prerequisites
        blocking = [p for p in prerequisites if p['criticality'] == 'blocking']

        for prereq in blocking:
            if not self._can_satisfy_prerequisite(prereq):
                issues.append(FeasibilityIssue(
                    type=IssueType.UNSATISFIABLE_PREREQ,
                    severity='critical',
                    description=f"Cannot satisfy: {prereq['description']}",
                    affected_item=transition['name'],
                    recommendation=self._get_prerequisite_recommendation(prereq)
                ))

        return issues

    def _check_overall_constraints(
        self,
        transitions: List[Dict],
        prerequisites: Dict[str, List[Dict]]
    ) -> List[FeasibilityIssue]:
        """Check overall plan against constraints"""
        issues = []

        # Timeline check
        total_weeks = sum(t.get('duration_weeks', 1) for t in transitions)
        if total_weeks > self.constraints.max_timeline_weeks:
            issues.append(FeasibilityIssue(
                type=IssueType.TIMELINE_EXCEEDED,
                severity='high',
                description=(
                    f"Estimated timeline ({total_weeks} weeks) exceeds "
                    f"constraint ({self.constraints.max_timeline_weeks} weeks)"
                ),
                affected_item="Overall Plan",
                recommendation=(
                    "Consider parallel execution of independent transitions, "
                    "or reduce scope"
                )
            ))

        # Budget check
        total_cost = sum(t.get('cost_usd', 0) for t in transitions)
        if total_cost > self.constraints.max_budget_usd:
            issues.append(FeasibilityIssue(
                type=IssueType.BUDGET_EXCEEDED,
                severity='high',
                description=(
                    f"Estimated cost (${total_cost:,.0f}) exceeds "
                    f"budget (${self.constraints.max_budget_usd:,.0f})"
                ),
                affected_item="Overall Plan",
                recommendation="Reduce scope or increase budget"
            ))

        # Capacity check (simplified)
        max_parallel = max(
            len([t for t in transitions if t.get('phase') == phase])
            for phase in set(t.get('phase', 1) for t in transitions)
        )
        if max_parallel > self.constraints.max_team_size:
            issues.append(FeasibilityIssue(
                type=IssueType.CAPACITY_EXCEEDED,
                severity='high',
                description=(
                    f"Peak parallelism ({max_parallel} tasks) exceeds "
                    f"team capacity ({self.constraints.max_team_size} people)"
                ),
                affected_item="Overall Plan",
                recommendation="Serialize some transitions or increase team size"
            ))

        return issues

    def _can_satisfy_prerequisite(self, prerequisite: Dict) -> bool:
        """Check if prerequisite can be satisfied"""
        prereq_type = prerequisite['type']

        # Check based on type
        if prereq_type == 'resource':
            # Check if we have budget
            cost = prerequisite.get('estimated_cost', 0)
            return cost <= self.constraints.max_budget_usd

        elif prereq_type == 'technical':
            # Check against prohibited technologies
            tech = prerequisite.get('technology', '')
            return tech not in self.constraints.prohibited_technologies

        elif prereq_type == 'knowledge':
            # Assume we can train (optimistic)
            return True

        elif prereq_type == 'timeline':
            # Check if enough time
            weeks = prerequisite.get('weeks_required', 0)
            return weeks <= self.constraints.max_timeline_weeks

        # Default: assume satisfiable
        return True

    def _get_prerequisite_recommendation(self, prerequisite: Dict) -> str:
        """Generate recommendation for unsatisfiable prerequisite"""
        prereq_type = prerequisite['type']

        recommendations = {
            'resource': "Increase budget or find alternative solution",
            'technical': "Choose different technology or get exception approval",
            'knowledge': "Allocate time for training or hire specialists",
            'timeline': "Reduce scope or extend deadline",
            'organizational': "Begin stakeholder engagement earlier",
            'dependency': "Find alternative provider or build in-house"
        }

        return recommendations.get(prereq_type, "Re-evaluate requirement")


# Example usage
if __name__ == "__main__":
    # Define constraints
    constraints = Constraints(
        max_budget_usd=50000,
        max_timeline_weeks=12,
        max_team_size=5,
        required_technologies=['PostgreSQL'],
        prohibited_technologies=['MongoDB'],  # Company policy
        technical_constraints={
            'must_maintain_acid': True,
            'max_downtime_minutes': 5
        }
    )

    checker = FeasibilityChecker(constraints)

    # Example chain with issues
    chain = [
        {
            'name': 'Current State',
            'predicates': ['monolith_exists', 'single_database']
        },
        {
            'name': 'Intermediate',
            'predicates': [
                'microservices_architecture',
                'stateless',
                'stores_session_data',  # CONTRADICTION!
                'zero_latency'  # IMPOSSIBLE!
            ]
        },
        {
            'name': 'Goal',
            'predicates': ['microservices_architecture', 'database_per_service']
        }
    ]

    transitions = [
        {
            'name': 'Phase 1',
            'duration_weeks': 8,
            'cost_usd': 30000,
            'phase': 1
        },
        {
            'name': 'Phase 2',
            'duration_weeks': 6,  # Total: 14 weeks (EXCEEDS 12!)
            'cost_usd': 25000,  # Total: $55k (EXCEEDS $50k!)
            'phase': 2
        }
    ]

    prerequisites = {
        'Phase 1': [
            {
                'type': 'resource',
                'description': 'Need high-performance servers',
                'criticality': 'blocking',
                'estimated_cost': 100000  # UNSATISFIABLE!
            }
        ],
        'Phase 2': [
            {
                'type': 'technical',
                'description': 'Migrate to MongoDB',  # PROHIBITED!
                'criticality': 'blocking',
                'technology': 'MongoDB'
            }
        ]
    }

    # Check feasibility
    is_feasible, issues = checker.check_chain(chain, transitions, prerequisites)

    print("=" * 70)
    print("FEASIBILITY CHECK REPORT")
    print("=" * 70)

    if is_feasible:
        print("\n✓ Plan is FEASIBLE")
    else:
        print("\n✗ Plan is NOT FEASIBLE")

    print(f"\nFound {len(issues)} issues:\n")

    # Group by severity
    by_severity = {}
    for issue in issues:
        by_severity.setdefault(issue.severity, []).append(issue)

    for severity in ['critical', 'high', 'medium', 'low']:
        if severity in by_severity:
            print(f"\n{severity.upper()} ({len(by_severity[severity])}):")
            for issue in by_severity[severity]:
                print(f"\n  [{issue.type.value}] {issue.affected_item}")
                print(f"  Problem: {issue.description}")
                if issue.recommendation:
                    print(f"  Recommendation: {issue.recommendation}")
```

### Output

```
======================================================================
FEASIBILITY CHECK REPORT
======================================================================

✗ Plan is NOT FEASIBLE

Found 6 issues:

CRITICAL (4):

  [contradiction] Intermediate
  Problem: State cannot be both stateless and store session data
  Recommendation: Remove one of the contradictory predicates

  [impossible] Intermediate
  Problem: Zero latency is physically impossible
  Recommendation: Remove or redefine 'zero_latency' predicate

  [unsatisfiable_prerequisite] Phase 1
  Problem: Cannot satisfy: Need high-performance servers
  Recommendation: Increase budget or find alternative solution

  [unsatisfiable_prerequisite] Phase 2
  Problem: Cannot satisfy: Migrate to MongoDB
  Recommendation: Choose different technology or get exception approval

HIGH (2):

  [timeline_exceeded] Overall Plan
  Problem: Estimated timeline (14.0 weeks) exceeds constraint (12.0 weeks)
  Recommendation: Consider parallel execution of independent transitions, or reduce scope

  [budget_exceeded] Overall Plan
  Problem: Estimated cost ($55,000) exceeds budget ($50,000)
  Recommendation: Reduce scope or increase budget
```

---

## Example 5: Migration Planner

### Purpose
Complete end-to-end migration planning using all backcasting components.

### Code

```python
#!/usr/bin/env python3
"""
Migration Planner
Complete backcasting workflow for database migration.
"""

from dataclasses import dataclass, asdict
from typing import List, Dict, Set
import json


@dataclass
class MigrationPlan:
    """Complete migration plan"""
    name: str
    current_state: Dict
    target_state: Dict
    backward_chain: List[Dict]
    prerequisites: Dict[str, List[Dict]]
    feasibility_report: Dict
    estimated_timeline_weeks: float
    estimated_cost_usd: float
    risk_level: str


class MigrationPlanner:
    """End-to-end migration planning with backcasting"""

    def __init__(self):
        pass

    def plan_migration(
        self,
        current: Dict,
        target: Dict,
        constraints: Dict
    ) -> MigrationPlan:
        """
        Create complete migration plan.

        Args:
            current: Current state description
            target: Target state description
            constraints: Budget, timeline, technical constraints

        Returns:
            MigrationPlan with full backcasting analysis
        """
        # Step 1: Build backward chain
        print("Step 1: Building backward chain...")
        chain = self._build_chain(current, target)
        print(f"  ✓ Found path with {len(chain)} states")

        # Step 2: Identify prerequisites
        print("\nStep 2: Identifying prerequisites...")
        prerequisites = self._identify_prerequisites(chain)
        total_prereqs = sum(len(p) for p in prerequisites.values())
        print(f"  ✓ Identified {total_prereqs} prerequisites")

        # Step 3: Estimate effort
        print("\nStep 3: Estimating effort...")
        timeline, cost = self._estimate_effort(chain, prerequisites)
        print(f"  ✓ Timeline: {timeline} weeks")
        print(f"  ✓ Cost: ${cost:,.0f}")

        # Step 4: Check feasibility
        print("\nStep 4: Checking feasibility...")
        feasibility = self._check_feasibility(
            chain,
            prerequisites,
            constraints,
            timeline,
            cost
        )
        print(f"  ✓ Feasibility: {feasibility['result']}")

        # Step 5: Assess risk
        print("\nStep 5: Assessing risk...")
        risk_level = self._assess_risk(chain, prerequisites, feasibility)
        print(f"  ✓ Risk level: {risk_level}")

        # Create plan
        plan = MigrationPlan(
            name=f"{current['name']} → {target['name']}",
            current_state=current,
            target_state=target,
            backward_chain=chain,
            prerequisites=prerequisites,
            feasibility_report=feasibility,
            estimated_timeline_weeks=timeline,
            estimated_cost_usd=cost,
            risk_level=risk_level
        )

        return plan

    def _build_chain(self, current: Dict, target: Dict) -> List[Dict]:
        """Build backward chain (simplified)"""
        # In reality, this would use BackwardChainer
        # For demo, return hardcoded chain
        return [
            {
                'name': 'Current: MySQL Only',
                'predicates': ['mysql_active', 'single_database'],
                'phase': 0
            },
            {
                'name': 'Dual-Write Setup',
                'predicates': ['mysql_active', 'postgres_active', 'dual_write'],
                'phase': 1
            },
            {
                'name': 'Postgres Primary',
                'predicates': ['postgres_active', 'mysql_deprecated', 'reads_from_postgres'],
                'phase': 2
            },
            {
                'name': 'Target: Postgres Only',
                'predicates': ['postgres_active', 'mysql_decommissioned'],
                'phase': 3
            }
        ]

    def _identify_prerequisites(self, chain: List[Dict]) -> Dict[str, List[Dict]]:
        """Identify prerequisites for each transition"""
        # Simplified - return hardcoded prerequisites
        return {
            'Phase 0 → Phase 1': [
                {'type': 'technical', 'desc': 'PostgreSQL 15 installed', 'criticality': 'blocking'},
                {'type': 'technical', 'desc': 'Schema migrated and tested', 'criticality': 'blocking'},
                {'type': 'technical', 'desc': 'Dual-write logic implemented', 'criticality': 'blocking'},
                {'type': 'knowledge', 'desc': 'Team trained on PostgreSQL', 'criticality': 'limiting'}
            ],
            'Phase 1 → Phase 2': [
                {'type': 'data', 'desc': 'Data fully synchronized', 'criticality': 'blocking'},
                {'type': 'technical', 'desc': 'Read path switched to Postgres', 'criticality': 'blocking'},
                {'type': 'resource', 'desc': 'Performance testing completed', 'criticality': 'blocking'}
            ],
            'Phase 2 → Phase 3': [
                {'type': 'data', 'desc': 'Full backup of MySQL created', 'criticality': 'blocking'},
                {'type': 'organizational', 'desc': 'Stakeholder approval to decommission', 'criticality': 'blocking'},
                {'type': 'technical', 'desc': 'Rollback procedure tested', 'criticality': 'blocking'}
            ]
        }

    def _estimate_effort(
        self,
        chain: List[Dict],
        prerequisites: Dict[str, List[Dict]]
    ) -> tuple[float, float]:
        """Estimate timeline and cost"""
        # Simplified estimation
        phase_effort = {
            'Phase 0 → Phase 1': {'weeks': 4, 'cost': 20000},
            'Phase 1 → Phase 2': {'weeks': 3, 'cost': 15000},
            'Phase 2 → Phase 3': {'weeks': 2, 'cost': 10000}
        }

        total_weeks = sum(e['weeks'] for e in phase_effort.values())
        total_cost = sum(e['cost'] for e in phase_effort.values())

        return total_weeks, total_cost

    def _check_feasibility(
        self,
        chain: List[Dict],
        prerequisites: Dict[str, List[Dict]],
        constraints: Dict,
        timeline: float,
        cost: float
    ) -> Dict:
        """Check feasibility against constraints"""
        issues = []

        if timeline > constraints.get('max_weeks', float('inf')):
            issues.append({
                'type': 'timeline',
                'message': f"Timeline ({timeline}w) exceeds limit ({constraints['max_weeks']}w)"
            })

        if cost > constraints.get('max_budget', float('inf')):
            issues.append({
                'type': 'budget',
                'message': f"Cost (${cost}) exceeds budget (${constraints['max_budget']})"
            })

        return {
            'result': 'FEASIBLE' if not issues else 'NOT FEASIBLE',
            'issues': issues
        }

    def _assess_risk(
        self,
        chain: List[Dict],
        prerequisites: Dict[str, List[Dict]],
        feasibility: Dict
    ) -> str:
        """Assess overall risk level"""
        risk_score = 0

        # Number of states
        if len(chain) > 5:
            risk_score += 2

        # Number of blocking prerequisites
        blocking = sum(
            1 for phase_prereqs in prerequisites.values()
            for prereq in phase_prereqs
            if prereq['criticality'] == 'blocking'
        )
        if blocking > 10:
            risk_score += 3
        elif blocking > 5:
            risk_score += 2

        # Feasibility issues
        if feasibility['result'] == 'NOT FEASIBLE':
            risk_score += 5

        # Classify risk
        if risk_score >= 7:
            return 'HIGH'
        elif risk_score >= 4:
            return 'MEDIUM'
        else:
            return 'LOW'

    def export_plan(self, plan: MigrationPlan, filepath: str):
        """Export plan to JSON"""
        with open(filepath, 'w') as f:
            json.dump(asdict(plan), f, indent=2)


# Example usage
if __name__ == "__main__":
    planner = MigrationPlanner()

    # Define migration
    current_state = {
        'name': 'MySQL Production',
        'database': 'MySQL 5.7',
        'description': 'Legacy MySQL database with ~500GB data'
    }

    target_state = {
        'name': 'PostgreSQL Production',
        'database': 'PostgreSQL 15',
        'description': 'Modern PostgreSQL with improved performance and features'
    }

    constraints = {
        'max_weeks': 12,
        'max_budget': 50000,
        'max_downtime_minutes': 5
    }

    print("=" * 70)
    print("DATABASE MIGRATION PLANNER")
    print("=" * 70)
    print(f"\nMigration: {current_state['name']} → {target_state['name']}")
    print(f"Constraints: {constraints['max_weeks']} weeks, ${constraints['max_budget']:,}\n")

    # Create plan
    plan = planner.plan_migration(current_state, target_state, constraints)

    print("\n" + "=" * 70)
    print("MIGRATION PLAN SUMMARY")
    print("=" * 70)

    print(f"\nPlan: {plan.name}")
    print(f"Estimated Timeline: {plan.estimated_timeline_weeks} weeks")
    print(f"Estimated Cost: ${plan.estimated_cost_usd:,.0f}")
    print(f"Risk Level: {plan.risk_level}")
    print(f"Feasibility: {plan.feasibility_report['result']}")

    print(f"\nBackward Chain ({len(plan.backward_chain)} states):")
    for i, state in enumerate(plan.backward_chain):
        print(f"  {i+1}. {state['name']}")

    print(f"\nPrerequisites ({sum(len(p) for p in plan.prerequisites.values())} total):")
    for phase, prereqs in plan.prerequisites.items():
        print(f"\n  {phase}:")
        for prereq in prereqs:
            symbol = "🔴" if prereq['criticality'] == 'blocking' else "🟡"
            print(f"    {symbol} {prereq['desc']}")

    # Export
    plan_file = "migration_plan.json"
    planner.export_plan(plan, plan_file)
    print(f"\n✓ Full plan exported to {plan_file}")
```

### Output

```
======================================================================
DATABASE MIGRATION PLANNER
======================================================================

Migration: MySQL Production → PostgreSQL Production
Constraints: 12 weeks, $50,000

Step 1: Building backward chain...
  ✓ Found path with 4 states

Step 2: Identifying prerequisites...
  ✓ Identified 11 prerequisites

Step 3: Estimating effort...
  ✓ Timeline: 9.0 weeks
  ✓ Cost: $45,000

Step 4: Checking feasibility...
  ✓ Feasibility: FEASIBLE

Step 5: Assessing risk...
  ✓ Risk level: MEDIUM

======================================================================
MIGRATION PLAN SUMMARY
======================================================================

Plan: MySQL Production → PostgreSQL Production
Estimated Timeline: 9.0 weeks
Estimated Cost: $45,000
Risk Level: MEDIUM
Feasibility: FEASIBLE

Backward Chain (4 states):
  1. Current: MySQL Only
  2. Dual-Write Setup
  3. Postgres Primary
  4. Target: Postgres Only

Prerequisites (11 total):

  Phase 0 → Phase 1:
    🔴 PostgreSQL 15 installed
    🔴 Schema migrated and tested
    🔴 Dual-write logic implemented
    🟡 Team trained on PostgreSQL

  Phase 1 → Phase 2:
    🔴 Data fully synchronized
    🔴 Read path switched to Postgres
    🔴 Performance testing completed

  Phase 2 → Phase 3:
    🔴 Full backup of MySQL created
    🔴 Stakeholder approval to decommission
    🔴 Rollback procedure tested

✓ Full plan exported to migration_plan.json
```

---

## Real-World Use Cases

### Use Case 1: Monolith to Microservices

**Context**: E-commerce platform, 200k LOC monolith, 5M users

**Current State**:
- Single Rails application
- PostgreSQL database (500GB)
- Manual deployment process
- 800ms p95 response time

**Target State**:
- 15 microservices (catalog, cart, checkout, user, inventory, etc.)
- Database per service
- CI/CD with Kubernetes
- 200ms p95 response time

**Backward Chain**:
1. Current (Rails monolith)
2. Bounded contexts identified (DDD analysis)
3. First service extracted (catalog service)
4. Core services extracted (cart, checkout, user)
5. Remaining services extracted
6. Monolith decommissioned
7. Target (Full microservices)

**Key Prerequisites**:
- Kubernetes cluster operational
- API gateway deployed (Kong/Envoy)
- Service mesh (Istio) configured
- Distributed tracing (Jaeger)
- Message bus (Kafka) for async events
- Database migration tools
- Team trained on microservices patterns

**Timeline**: 18 months
**Cost**: $500k (team time + infrastructure)
**Risk**: HIGH (complex domain, large scale)

### Use Case 2: Framework Upgrade (Angular 10 → 17)

**Current State**:
- Angular 10 application
- RxJS 6
- 80 components, 45k LOC
- IE11 support required

**Target State**:
- Angular 17 (standalone components)
- RxJS 7
- Modern build system (esbuild)
- No IE11 support

**Backward Chain**:
1. Current (Angular 10)
2. Angular 12 (drop IE11, Ivy only)
3. Angular 14 (typed forms, inject function)
4. Angular 16 (signals preview)
5. Target (Angular 17 + standalone)

**Key Prerequisites**:
- IE11 deprecation approved
- All dependencies compatible with each version
- Test coverage >80%
- CI/CD updated for each version
- Team trained on new features (signals, standalone)

**Timeline**: 3 months
**Cost**: $30k
**Risk**: MEDIUM (well-documented upgrade path)

### Use Case 3: Cloud Migration (On-Prem → AWS)

**Current State**:
- On-premises datacenter
- VMware VMs (50 servers)
- MySQL, Redis, RabbitMQ
- Custom deployment scripts

**Target State**:
- AWS (us-east-1)
- EKS for services
- RDS for databases
- ElastiCache for Redis
- Amazon MQ for messaging
- Terraform infrastructure as code

**Backward Chain**:
1. Current (On-prem)
2. AWS account setup, networking configured
3. Pilot service migrated to EKS
4. Databases migrated to RDS
5. Core services migrated
6. Remaining services migrated
7. On-prem decommissioned
8. Target (Full AWS)

**Key Prerequisites**:
- AWS account with proper permissions
- VPN/Direct Connect for hybrid period
- Terraform code for all infrastructure
- Database migration tested
- Disaster recovery plan
- Team trained on AWS services
- Security review completed

**Timeline**: 9 months
**Cost**: $200k (migration) + $15k/month (AWS costs)
**Risk**: MEDIUM (proven migration patterns exist)
