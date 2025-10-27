# Work Backcasting Framework - Patterns

## Table of Contents
1. [Pattern 1: End State Definition](#pattern-1-end-state-definition)
2. [Pattern 2: Backward Chaining](#pattern-2-backward-chaining)
3. [Pattern 3: Prerequisite Identification](#pattern-3-prerequisite-identification)
4. [Pattern 4: Feasibility Validation](#pattern-4-feasibility-validation)
5. [Pattern 5: Gap Analysis](#pattern-5-gap-analysis)
6. [Pattern Selection Matrix](#pattern-selection-matrix)
7. [Validation Strategies](#validation-strategies)

---

## Pattern 1: End State Definition

### Purpose
Define concrete, measurable, achievable target states with clear success criteria. The quality of the end state definition determines the quality of the entire backcasting process.

### When to Use
- Always the first step in any backcasting exercise
- When goals are vague or ambiguous ("make it better")
- When stakeholders have different interpretations of success
- When planning large migrations or architecture changes

### Structure

```yaml
end_state:
  name: "String identifier"
  description: "Clear prose description"

  # SMART criteria
  specific:
    - "Concrete requirement 1"
    - "Concrete requirement 2"

  measurable:
    metrics:
      - name: "Metric name"
        target: "Numeric target"
        current: "Current value"
        unit: "Unit of measurement"

  achievable:
    constraints:
      - type: "technical|resource|timeline|organizational"
        description: "Constraint description"
        severity: "blocking|limiting|informational"

  relevant:
    business_alignment:
      - "Business objective 1"
      - "Business objective 2"

  time_bound:
    deadline: "ISO 8601 date"
    milestones:
      - date: "ISO 8601 date"
        deliverable: "What must be true"

  # System state description
  architecture:
    components: ["List of services/modules"]
    patterns: ["Architecture patterns in use"]
    technologies: ["Tech stack"]

  capabilities:
    functional: ["Feature 1", "Feature 2"]
    non_functional:
      performance: ["Response time < X", "Throughput > Y"]
      reliability: ["Uptime > X%", "MTBF > Y"]
      scalability: ["Handles X concurrent users"]
      security: ["Meets standard X"]

  # Acceptance criteria
  success_criteria:
    - criterion: "Specific test or condition"
      verification: "How to verify"
      priority: "must-have|should-have|nice-to-have"
```

### Implementation Algorithm

```python
class EndStateDefinition:
    """Structured end state with validation"""

    def __init__(self, name, description):
        self.name = name
        self.description = description
        self.metrics = []
        self.constraints = []
        self.success_criteria = []
        self.architecture = {}
        self.capabilities = {}

    def add_metric(self, name, current, target, unit):
        """Add a measurable metric"""
        self.metrics.append({
            'name': name,
            'current': current,
            'target': target,
            'unit': unit,
            'gap': target - current
        })

    def add_constraint(self, type, description, severity):
        """Add a constraint (technical, resource, timeline, etc.)"""
        self.constraints.append({
            'type': type,
            'description': description,
            'severity': severity
        })

    def add_success_criterion(self, criterion, verification, priority):
        """Add an acceptance criterion"""
        self.success_criteria.append({
            'criterion': criterion,
            'verification': verification,
            'priority': priority
        })

    def validate_smart(self):
        """Validate that end state meets SMART criteria"""
        issues = []

        # Specific: Must have clear description
        if not self.description or len(self.description) < 20:
            issues.append("Description too vague (must be >20 chars)")

        # Measurable: Must have at least one metric
        if len(self.metrics) == 0:
            issues.append("No measurable metrics defined")

        # Achievable: Check for blocking constraints
        blocking = [c for c in self.constraints if c['severity'] == 'blocking']
        if blocking:
            issues.append(f"Has {len(blocking)} blocking constraints")

        # Relevant: Must have business alignment
        if not self.capabilities:
            issues.append("No capabilities defined (relevance unclear)")

        # Time-bound: Must have deadline (checked externally)

        return len(issues) == 0, issues

    def to_dict(self):
        """Export as dictionary for serialization"""
        return {
            'name': self.name,
            'description': self.description,
            'metrics': self.metrics,
            'constraints': self.constraints,
            'success_criteria': self.success_criteria,
            'architecture': self.architecture,
            'capabilities': self.capabilities
        }
```

### Example: Database Migration End State

```python
end_state = EndStateDefinition(
    name="PostgreSQL Migration Complete",
    description="All production data migrated from MySQL to PostgreSQL "
                "with zero data loss and <5min downtime"
)

# Metrics
end_state.add_metric("data_completeness", 0, 100, "%")
end_state.add_metric("query_performance", 800, 200, "ms (p95)")
end_state.add_metric("downtime", 0, 5, "minutes")

# Constraints
end_state.add_constraint(
    "timeline",
    "Must complete within 3 months",
    "limiting"
)
end_state.add_constraint(
    "resource",
    "Budget capped at $50k",
    "limiting"
)
end_state.add_constraint(
    "technical",
    "Must maintain ACID guarantees",
    "blocking"
)

# Success criteria
end_state.add_success_criterion(
    "All MySQL queries translated to PostgreSQL",
    "Run test suite against PostgreSQL",
    "must-have"
)
end_state.add_success_criterion(
    "Data integrity verified",
    "Compare row counts and checksums",
    "must-have"
)

# Architecture
end_state.architecture = {
    'database': 'PostgreSQL 15',
    'connection_pool': 'pgbouncer',
    'backup': 'pg_dump + S3',
    'monitoring': 'Prometheus + Grafana'
}

# Validate
is_valid, issues = end_state.validate_smart()
```

### Anti-Patterns

**Vague Goals**:
```
Bad:  "Make the system faster"
Good: "Reduce API p95 latency from 800ms to <200ms under 5k RPS"
```

**Unmeasurable**:
```
Bad:  "Improve user experience"
Good: "Increase NPS from 45 to 65, reduce support tickets by 30%"
```

**Unrealistic**:
```
Bad:  "Zero bugs in production"
Good: "Reduce critical bugs to <5 per quarter, resolve all P0 within 24h"
```

---

## Pattern 2: Backward Chaining

### Purpose
Build a reverse dependency graph from target state to current state by repeatedly asking "what must be true immediately before this state?"

### When to Use
- After end state is clearly defined
- When planning complex migrations with many steps
- To identify the critical path and dependencies
- To ensure no prerequisites are missed

### Algorithm

```python
class BackwardChainer:
    """Build dependency chain from goal to current state"""

    def __init__(self, knowledge_base):
        self.kb = knowledge_base  # Rules about state transitions

    def chain(self, current_state, goal_state, max_depth=20):
        """
        Build backward chain from goal to current.

        Returns: List of states from current to goal
        """
        chain = self._backward_search(
            current_state,
            goal_state,
            visited=set(),
            depth=0,
            max_depth=max_depth
        )

        if chain is None:
            raise ValueError("No path found from current to goal")

        return list(reversed(chain))

    def _backward_search(self, current, goal, visited, depth, max_depth):
        """Recursive backward search with cycle detection"""

        # Base case: reached current state
        if self._states_equal(goal, current):
            return [current]

        # Depth limit
        if depth > max_depth:
            return None

        # Cycle detection
        goal_id = self._state_id(goal)
        if goal_id in visited:
            return None
        visited.add(goal_id)

        # Find rules that can produce this goal state
        applicable_rules = self.kb.rules_producing(goal)

        for rule in applicable_rules:
            # The prerequisite state
            prerequisite = rule.prerequisite_state

            # Recursively find path to prerequisite
            sub_chain = self._backward_search(
                current,
                prerequisite,
                visited.copy(),
                depth + 1,
                max_depth
            )

            if sub_chain is not None:
                return sub_chain + [goal]

        return None  # No path found

    def _states_equal(self, state1, state2):
        """Check if two states are equivalent"""
        return state1.get_predicates() == state2.get_predicates()

    def _state_id(self, state):
        """Generate unique ID for state (for cycle detection)"""
        predicates = sorted(state.get_predicates())
        return hash(tuple(predicates))
```

### State Representation

```python
class State:
    """Represents a system state as a set of predicates"""

    def __init__(self, name, predicates=None):
        self.name = name
        self.predicates = set(predicates) if predicates else set()
        self.metadata = {}

    def add_predicate(self, predicate):
        """Add a true predicate to this state"""
        self.predicates.add(predicate)

    def remove_predicate(self, predicate):
        """Remove a predicate from this state"""
        self.predicates.discard(predicate)

    def has_predicate(self, predicate):
        """Check if predicate is true in this state"""
        return predicate in self.predicates

    def get_predicates(self):
        """Return all true predicates"""
        return self.predicates

    def difference(self, other_state):
        """Find predicates that differ from another state"""
        return {
            'added': self.predicates - other_state.predicates,
            'removed': other_state.predicates - self.predicates
        }
```

### Transition Rules

```python
class TransitionRule:
    """Represents a valid state transition"""

    def __init__(self, name, prerequisite_state, result_state, action):
        self.name = name
        self.prerequisite = prerequisite_state
        self.result = result_state
        self.action = action  # What causes the transition

    def applicable_to(self, state):
        """Check if this rule can be applied to produce the given state"""
        return self._states_match(self.result, state)

    def _states_match(self, template, actual):
        """Check if actual state matches template"""
        return template.predicates.issubset(actual.predicates)
```

### Example: Microservices Migration

```python
# Define states
current = State("Monolith", [
    "single_codebase",
    "shared_database",
    "tight_coupling"
])

intermediate1 = State("Modular Monolith", [
    "single_codebase",
    "shared_database",
    "bounded_contexts_identified",
    "module_boundaries_defined"
])

intermediate2 = State("Service Extraction Started", [
    "monolith_exists",
    "first_service_extracted",
    "api_gateway_deployed",
    "service_mesh_ready"
])

goal = State("Microservices", [
    "services_independently_deployable",
    "database_per_service",
    "async_communication",
    "distributed_tracing_enabled"
])

# Define transition rules
rule1 = TransitionRule(
    "identify_boundaries",
    prerequisite_state=current,
    result_state=intermediate1,
    action="Domain-driven design analysis"
)

rule2 = TransitionRule(
    "extract_first_service",
    prerequisite_state=intermediate1,
    result_state=intermediate2,
    action="Strangler fig pattern"
)

rule3 = TransitionRule(
    "complete_extraction",
    prerequisite_state=intermediate2,
    result_state=goal,
    action="Extract all remaining services"
)

# Build knowledge base and chain
kb = KnowledgeBase([rule1, rule2, rule3])
chainer = BackwardChainer(kb)
chain = chainer.chain(current, goal)

# Result: [current, intermediate1, intermediate2, goal]
```

### Validation

After building a backward chain, validate:

1. **Completeness**: All states between current and goal are included
2. **Ordering**: Each state can actually transition to the next
3. **No Cycles**: No state appears twice
4. **No Gaps**: No missing intermediate states

```python
def validate_chain(chain, current, goal):
    """Validate backward chain"""
    errors = []

    # Check endpoints
    if chain[0] != current:
        errors.append(f"Chain doesn't start at current state")
    if chain[-1] != goal:
        errors.append(f"Chain doesn't end at goal state")

    # Check for cycles
    if len(chain) != len(set(s.name for s in chain)):
        errors.append("Chain contains cycles")

    # Check transitions
    for i in range(len(chain) - 1):
        from_state = chain[i]
        to_state = chain[i + 1]
        if not can_transition(from_state, to_state):
            errors.append(f"Invalid transition: {from_state.name} -> {to_state.name}")

    return len(errors) == 0, errors
```

---

## Pattern 3: Prerequisite Identification

### Purpose
Systematically identify all dependencies, blockers, and enabling conditions required for each state transition in the backward chain.

### When to Use
- For each step in the backward chain
- When validating plan completeness
- To identify hidden dependencies early
- To prevent "surprise" prerequisites during execution

### Categories of Prerequisites

```python
class Prerequisite:
    """Represents a requirement for a state transition"""

    TYPES = [
        'technical',      # Technology, infrastructure, tools
        'data',          # Data migration, schema, quality
        'knowledge',     # Skills, training, expertise
        'resource',      # Budget, hardware, licenses
        'organizational', # Approvals, process changes
        'dependency',    # External systems, third-party services
        'compliance'     # Regulatory, security, legal
    ]

    def __init__(self, type, description, criticality):
        assert type in self.TYPES
        self.type = type
        self.description = description
        self.criticality = criticality  # 'blocking', 'limiting', 'optional'
        self.satisfied = False
        self.verification = None

    def mark_satisfied(self, verification_evidence):
        """Mark prerequisite as satisfied with evidence"""
        self.satisfied = True
        self.verification = verification_evidence
```

### Identification Algorithm

```python
class PrerequisiteIdentifier:
    """Systematically identify prerequisites for state transitions"""

    def __init__(self, transition_rules):
        self.rules = transition_rules

    def identify_all(self, backward_chain):
        """
        Identify prerequisites for all transitions in chain.

        Returns: Dict mapping transition -> list of prerequisites
        """
        prerequisites = {}

        for i in range(len(backward_chain) - 1):
            from_state = backward_chain[i]
            to_state = backward_chain[i + 1]

            transition_id = f"{from_state.name} -> {to_state.name}"
            prerequisites[transition_id] = self.identify_for_transition(
                from_state,
                to_state
            )

        return prerequisites

    def identify_for_transition(self, from_state, to_state):
        """Identify prerequisites for a single transition"""
        prereqs = []

        # Analyze state differences
        diff = to_state.difference(from_state)

        # For each added predicate, find what enables it
        for predicate in diff['added']:
            prereqs.extend(self._prerequisites_for_predicate(predicate))

        # For each removed predicate, find what must be in place
        for predicate in diff['removed']:
            prereqs.extend(self._prerequisites_for_removal(predicate))

        # Check for implicit prerequisites
        prereqs.extend(self._implicit_prerequisites(from_state, to_state))

        return prereqs

    def _prerequisites_for_predicate(self, predicate):
        """Find what's needed to make this predicate true"""
        # This would use domain knowledge
        # Example implementation:
        prereq_map = {
            'database_migrated': [
                Prerequisite('technical', 'Migration scripts tested', 'blocking'),
                Prerequisite('data', 'Data validation complete', 'blocking'),
                Prerequisite('resource', 'Sufficient storage allocated', 'blocking')
            ],
            'service_deployed': [
                Prerequisite('technical', 'CI/CD pipeline configured', 'blocking'),
                Prerequisite('technical', 'Health checks implemented', 'blocking'),
                Prerequisite('resource', 'Production infrastructure ready', 'blocking')
            ]
        }
        return prereq_map.get(predicate, [])

    def _prerequisites_for_removal(self, predicate):
        """Find what's needed before removing this predicate"""
        # Example: Before removing old database, need backup
        removal_map = {
            'legacy_database_active': [
                Prerequisite('data', 'Full database backup created', 'blocking'),
                Prerequisite('technical', 'Rollback plan documented', 'blocking')
            ]
        }
        return removal_map.get(predicate, [])

    def _implicit_prerequisites(self, from_state, to_state):
        """Find prerequisites not directly tied to predicate changes"""
        # These are context-dependent
        # Example: organizational prerequisites
        return [
            Prerequisite('organizational', 'Stakeholder approval obtained', 'blocking'),
            Prerequisite('knowledge', 'Team trained on new system', 'limiting')
        ]
```

### Systematic Checklist

For each transition, ask:

```python
PREREQUISITE_CHECKLIST = {
    'technical': [
        "What infrastructure is required?",
        "What tools must be in place?",
        "What dependencies must be available?",
        "What technical debt must be addressed?"
    ],
    'data': [
        "What data must be migrated?",
        "What schema changes are needed?",
        "What data quality issues must be resolved?",
        "What backups are required?"
    ],
    'knowledge': [
        "What skills does the team need?",
        "What training is required?",
        "What documentation must exist?",
        "What subject matter experts are needed?"
    ],
    'resource': [
        "What budget is required?",
        "What hardware is needed?",
        "What licenses must be purchased?",
        "What staff allocation is required?"
    ],
    'organizational': [
        "What approvals are needed?",
        "What process changes are required?",
        "What communication plans are needed?",
        "What stakeholder buy-in is required?"
    ],
    'dependency': [
        "What external systems must be ready?",
        "What third-party services are required?",
        "What APIs must be available?",
        "What vendor commitments are needed?"
    ],
    'compliance': [
        "What regulatory requirements apply?",
        "What security reviews are needed?",
        "What legal approvals are required?",
        "What audit trails must exist?"
    ]
}
```

### Example: API Gateway Deployment Prerequisites

```python
transition = "Monolith -> API Gateway Deployed"

prereqs = [
    # Technical
    Prerequisite(
        'technical',
        'API Gateway software selected and tested',
        'blocking'
    ),
    Prerequisite(
        'technical',
        'Routing rules defined for all endpoints',
        'blocking'
    ),
    Prerequisite(
        'technical',
        'SSL certificates obtained and configured',
        'blocking'
    ),

    # Data
    Prerequisite(
        'data',
        'API endpoint inventory complete',
        'blocking'
    ),

    # Knowledge
    Prerequisite(
        'knowledge',
        'Team trained on API Gateway operations',
        'limiting'
    ),

    # Resource
    Prerequisite(
        'resource',
        'Infrastructure provisioned (CPU, memory, network)',
        'blocking'
    ),

    # Organizational
    Prerequisite(
        'organizational',
        'Architecture review approved',
        'blocking'
    ),

    # Dependency
    Prerequisite(
        'dependency',
        'DNS configuration can be updated',
        'blocking'
    ),

    # Compliance
    Prerequisite(
        'compliance',
        'Security scan completed',
        'limiting'
    )
]
```

---

## Pattern 4: Feasibility Validation

### Purpose
Validate that each state in the backward chain is achievable within real-world constraints (technical, resource, timeline, organizational).

### When to Use
- After backward chain is complete
- Before committing to execution plan
- When resource constraints are tight
- To identify blocking issues early

### Validation Dimensions

```python
class FeasibilityValidator:
    """Validate feasibility of backward chain"""

    def __init__(self, constraints):
        self.constraints = constraints

    def validate(self, backward_chain, prerequisites):
        """
        Validate entire chain for feasibility.

        Returns: (is_feasible, issues)
        """
        issues = []

        # Check each state
        for state in backward_chain:
            state_issues = self._validate_state(state)
            issues.extend(state_issues)

        # Check each transition
        for transition_id, prereq_list in prerequisites.items():
            transition_issues = self._validate_transition(
                transition_id,
                prereq_list
            )
            issues.extend(transition_issues)

        # Check overall constraints
        overall_issues = self._validate_overall(backward_chain, prerequisites)
        issues.extend(overall_issues)

        return len(issues) == 0, issues

    def _validate_state(self, state):
        """Validate a single state for internal consistency"""
        issues = []

        # Check for contradictory predicates
        predicates = state.get_predicates()
        contradictions = self._find_contradictions(predicates)
        if contradictions:
            issues.append({
                'type': 'contradiction',
                'state': state.name,
                'details': contradictions
            })

        # Check for impossible predicates
        for predicate in predicates:
            if not self._is_technically_possible(predicate):
                issues.append({
                    'type': 'impossible',
                    'state': state.name,
                    'predicate': predicate
                })

        return issues

    def _validate_transition(self, transition_id, prerequisites):
        """Validate prerequisites for a transition"""
        issues = []

        # Check if all blocking prerequisites can be satisfied
        blocking = [p for p in prerequisites if p.criticality == 'blocking']

        for prereq in blocking:
            if not self._can_satisfy_prerequisite(prereq):
                issues.append({
                    'type': 'unsatisfiable_prerequisite',
                    'transition': transition_id,
                    'prerequisite': prereq.description
                })

        return issues

    def _validate_overall(self, chain, prerequisites):
        """Validate overall plan constraints"""
        issues = []

        # Timeline validation
        estimated_duration = self._estimate_duration(chain, prerequisites)
        if estimated_duration > self.constraints.get('max_duration'):
            issues.append({
                'type': 'timeline_exceeded',
                'estimated': estimated_duration,
                'limit': self.constraints['max_duration']
            })

        # Resource validation
        estimated_cost = self._estimate_cost(chain, prerequisites)
        if estimated_cost > self.constraints.get('max_budget'):
            issues.append({
                'type': 'budget_exceeded',
                'estimated': estimated_cost,
                'limit': self.constraints['max_budget']
            })

        # Capacity validation
        required_people = self._estimate_people(chain, prerequisites)
        if required_people > self.constraints.get('max_team_size'):
            issues.append({
                'type': 'capacity_exceeded',
                'estimated': required_people,
                'limit': self.constraints['max_team_size']
            })

        return issues

    def _find_contradictions(self, predicates):
        """Find contradictory predicates in a state"""
        # Example: Can't be both "stateless" and "stores_session_data"
        contradiction_rules = [
            ({'stateless', 'stores_session_data'}, "Can't be stateless and store session data"),
            ({'synchronous', 'async_only'}, "Can't be both sync and async"),
            ({'single_database', 'database_per_service'}, "Contradictory database patterns")
        ]

        contradictions = []
        for rule_predicates, message in contradiction_rules:
            if rule_predicates.issubset(predicates):
                contradictions.append(message)

        return contradictions

    def _is_technically_possible(self, predicate):
        """Check if predicate is technically achievable"""
        # Example: Some predicates might be physically impossible
        impossible = [
            'zero_latency',
            'infinite_scalability',
            'perfect_security'
        ]
        return predicate not in impossible

    def _can_satisfy_prerequisite(self, prerequisite):
        """Check if prerequisite can be satisfied"""
        # This would check against available resources, knowledge, etc.
        # Simplified example:
        if prerequisite.type == 'resource':
            return self._has_sufficient_resources(prerequisite)
        elif prerequisite.type == 'knowledge':
            return self._has_required_skills(prerequisite)
        return True  # Assume satisfiable by default

    def _estimate_duration(self, chain, prerequisites):
        """Estimate time required for entire chain"""
        # Sum of estimated times for each transition
        total = 0
        for transition_id, prereq_list in prerequisites.items():
            total += self._estimate_transition_duration(prereq_list)
        return total

    def _estimate_cost(self, chain, prerequisites):
        """Estimate total cost"""
        total = 0
        for transition_id, prereq_list in prerequisites.items():
            for prereq in prereq_list:
                total += self._estimate_prerequisite_cost(prereq)
        return total

    def _estimate_people(self, chain, prerequisites):
        """Estimate required team size"""
        # Find peak parallelism
        return len(prerequisites) // 3  # Simplified
```

### Constraint Types

```python
class Constraints:
    """System constraints for feasibility validation"""

    def __init__(self):
        self.technical = {}
        self.resource = {}
        self.timeline = {}
        self.organizational = {}

    def add_technical(self, name, value):
        """Add technical constraint"""
        self.technical[name] = value

    def add_resource(self, name, available, required_unit):
        """Add resource constraint"""
        self.resource[name] = {
            'available': available,
            'unit': required_unit
        }

    def add_timeline(self, deadline):
        """Add timeline constraint"""
        self.timeline['deadline'] = deadline

    def add_organizational(self, name, value):
        """Add organizational constraint"""
        self.organizational[name] = value

# Example usage
constraints = Constraints()
constraints.add_resource('budget', 100000, 'USD')
constraints.add_resource('engineers', 5, 'people')
constraints.add_timeline('2024-12-31')
constraints.add_technical('must_use_postgres', True)
constraints.add_organizational('requires_security_review', True)
```

---

## Pattern 5: Gap Analysis

### Purpose
Compare current state to target state across all dimensions to quantify gaps and identify closure strategies.

### When to Use
- To validate starting point
- To size the effort required
- To identify capability gaps
- To prioritize development areas

### Gap Analysis Framework

```python
class GapAnalyzer:
    """Analyze gaps between current and target states"""

    DIMENSIONS = [
        'architecture',
        'capabilities',
        'data',
        'infrastructure',
        'skills',
        'process',
        'security',
        'compliance'
    ]

    def __init__(self, current_state, target_state):
        self.current = current_state
        self.target = target_state
        self.gaps = {}

    def analyze_all(self):
        """Analyze gaps across all dimensions"""
        for dimension in self.DIMENSIONS:
            self.gaps[dimension] = self._analyze_dimension(dimension)
        return self.gaps

    def _analyze_dimension(self, dimension):
        """Analyze a single dimension"""
        current_attrs = self.current.get_attributes(dimension)
        target_attrs = self.target.get_attributes(dimension)

        gap = {
            'missing': target_attrs - current_attrs,
            'obsolete': current_attrs - target_attrs,
            'severity': self._calculate_severity(
                target_attrs - current_attrs
            ),
            'effort': self._estimate_effort(
                target_attrs - current_attrs
            )
        }

        return gap

    def _calculate_severity(self, missing_attrs):
        """Calculate severity of gaps"""
        # Severity based on number and criticality of missing attrs
        critical_count = sum(1 for attr in missing_attrs if attr.critical)
        if critical_count > 5:
            return 'critical'
        elif critical_count > 2:
            return 'high'
        elif len(missing_attrs) > 10:
            return 'medium'
        else:
            return 'low'

    def _estimate_effort(self, missing_attrs):
        """Estimate effort to close gaps"""
        # Sum effort for each missing attribute
        return sum(attr.effort_estimate for attr in missing_attrs)

    def prioritize_gaps(self):
        """Prioritize gaps by severity and effort"""
        prioritized = []

        for dimension, gap in self.gaps.items():
            prioritized.append({
                'dimension': dimension,
                'severity': gap['severity'],
                'effort': gap['effort'],
                'priority': self._calculate_priority(
                    gap['severity'],
                    gap['effort']
                )
            })

        return sorted(prioritized, key=lambda x: x['priority'], reverse=True)

    def _calculate_priority(self, severity, effort):
        """Calculate priority score (higher = more urgent)"""
        severity_score = {
            'critical': 10,
            'high': 7,
            'medium': 4,
            'low': 1
        }[severity]

        # Priority = severity / effort (want high impact, low effort)
        return severity_score / max(effort, 1)
```

### Example: Architecture Gap Analysis

```python
# Current state
current = State("Monolith")
current.architecture = {
    'pattern': 'monolith',
    'database': 'single_mysql',
    'deployment': 'manual',
    'monitoring': 'basic_logs'
}

# Target state
target = State("Microservices")
target.architecture = {
    'pattern': 'microservices',
    'database': 'postgres_per_service',
    'deployment': 'kubernetes',
    'monitoring': 'distributed_tracing'
}

# Analyze
analyzer = GapAnalyzer(current, target)
gaps = analyzer.analyze_all()

# Result:
# {
#   'architecture': {
#     'missing': ['microservices_pattern', 'service_mesh', 'api_gateway'],
#     'obsolete': ['monolith_pattern'],
#     'severity': 'critical',
#     'effort': 500  # person-hours
#   },
#   'infrastructure': {
#     'missing': ['kubernetes', 'container_registry', 'helm_charts'],
#     'obsolete': ['manual_deployment'],
#     'severity': 'high',
#     'effort': 200
#   },
#   ...
# }
```

---

## Pattern Selection Matrix

| Your Situation | Recommended Pattern | Next Pattern |
|----------------|---------------------|--------------|
| Starting fresh project | End State Definition | Gap Analysis |
| Have vague requirements | End State Definition | Prerequisite Identification |
| Have clear end state | Backward Chaining | Prerequisite Identification |
| Have backward chain | Prerequisite Identification | Feasibility Validation |
| Need to validate plan | Feasibility Validation | Gap Analysis |
| Sizing the effort | Gap Analysis | Feasibility Validation |
| Stuck in planning | Prerequisite Identification | Backward Chaining |
| Facing constraints | Feasibility Validation | Gap Analysis |

---

## Validation Strategies

### End State Validation
1. **Five Whys**: Ask "why" 5 times to ensure goal clarity
2. **Prototype**: Build quick mockup of end state
3. **Acceptance Tests**: Write tests for end state before building
4. **Stakeholder Review**: Get explicit sign-off on end state

### Chain Validation
1. **Forward Walk**: Walk forward through chain, verify each step
2. **Peer Review**: Have team member review chain for gaps
3. **State Consistency**: Ensure no contradictory predicates
4. **Completeness Check**: Verify no missing intermediate states

### Prerequisite Validation
1. **Checklist**: Run through systematic prerequisite checklist
2. **Expert Review**: Have domain experts review prerequisites
3. **Historical Analysis**: Check similar past projects for missed items
4. **Team Workshop**: Brainstorm prerequisites with full team

### Feasibility Validation
1. **Technical Spike**: Prototype risky transitions
2. **Resource Planning**: Allocate actual resources to see if available
3. **Timeline Estimation**: Use historical data to validate timeline
4. **Constraint Checking**: Verify all constraints are satisfiable

### Gap Analysis Validation
1. **Capability Mapping**: Map each capability to current vs target
2. **Skills Assessment**: Survey team for skill gaps
3. **Architecture Review**: Compare current vs target architectures
4. **Vendor Analysis**: Identify technology gaps and solutions
