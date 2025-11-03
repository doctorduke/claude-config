# Work Backcasting Framework - Reference

## Table of Contents
1. [Backward Chaining Algorithms](#backward-chaining-algorithms)
2. [Constraint Satisfaction Solvers](#constraint-satisfaction-solvers)
3. [Planning Domain Definition Languages](#planning-domain-definition-languages)
4. [Validation Checklist Templates](#validation-checklist-templates)
5. [Gap Analysis Frameworks](#gap-analysis-frameworks)
6. [Migration Pattern Catalog](#migration-pattern-catalog)
7. [API Documentation](#api-documentation)

---

## Backward Chaining Algorithms

### Basic Backward Search

```python
def backward_search(current, goal, transitions):
    """
    Simple backward search from goal to current.

    Args:
        current: Starting state
        goal: Target state
        transitions: List of (from_state, to_state, action) tuples

    Returns:
        List of states from current to goal, or None
    """
    from collections import deque

    queue = deque([(goal, [goal])])
    visited = {goal}

    while queue:
        state, path = queue.popleft()

        if state == current:
            return list(reversed(path))

        # Find predecessors
        for from_state, to_state, action in transitions:
            if to_state == state and from_state not in visited:
                visited.add(from_state)
                queue.append((from_state, path + [from_state]))

    return None
```

### A* Backward Search (Heuristic)

```python
import heapq

def a_star_backward(current, goal, transitions, heuristic_fn):
    """
    A* backward search with heuristic.

    Args:
        current: Starting state
        goal: Target state
        transitions: List of (from_state, to_state, action, cost) tuples
        heuristic_fn: Function estimating cost from state to current

    Returns:
        (path, total_cost) or (None, inf)
    """
    # Priority queue: (f_score, state, path, g_score)
    frontier = [(0, goal, [goal], 0)]
    visited = set()

    while frontier:
        f_score, state, path, g_score = heapq.heappop(frontier)

        if state in visited:
            continue
        visited.add(state)

        if state == current:
            return list(reversed(path)), g_score

        # Expand predecessors
        for from_state, to_state, action, cost in transitions:
            if to_state == state and from_state not in visited:
                new_g = g_score + cost
                new_h = heuristic_fn(from_state, current)
                new_f = new_g + new_h
                heapq.heappush(frontier, (
                    new_f,
                    from_state,
                    path + [from_state],
                    new_g
                ))

    return None, float('inf')
```

### Depth-First Backward Chaining

```python
def dfs_backward(current, goal, transitions, max_depth=20):
    """
    Depth-first backward chaining with depth limit.

    Args:
        current: Starting state
        goal: Target state
        transitions: List of (from_state, to_state, action) tuples
        max_depth: Maximum chain length

    Returns:
        List of states from current to goal, or None
    """
    def dfs_helper(state, path, visited, depth):
        if state == current:
            return list(reversed(path))

        if depth >= max_depth:
            return None

        for from_state, to_state, action in transitions:
            if to_state == state and from_state not in visited:
                visited.add(from_state)
                result = dfs_helper(
                    from_state,
                    path + [from_state],
                    visited.copy(),
                    depth + 1
                )
                if result:
                    return result

        return None

    return dfs_helper(goal, [goal], {goal}, 0)
```

---

## Constraint Satisfaction Solvers

### Basic CSP Solver

```python
class CSP:
    """Constraint Satisfaction Problem solver"""

    def __init__(self, variables, domains, constraints):
        """
        Args:
            variables: List of variable names
            domains: Dict of {variable: [possible_values]}
            constraints: List of (constraint_fn, variables) tuples
        """
        self.variables = variables
        self.domains = domains
        self.constraints = constraints

    def is_consistent(self, assignment):
        """Check if partial assignment satisfies constraints"""
        for constraint_fn, vars_involved in self.constraints:
            # Only check if all involved variables are assigned
            if all(v in assignment for v in vars_involved):
                values = [assignment[v] for v in vars_involved]
                if not constraint_fn(*values):
                    return False
        return True

    def backtracking_search(self):
        """Solve CSP using backtracking"""
        return self._backtrack({})

    def _backtrack(self, assignment):
        """Recursive backtracking"""
        # If complete, return assignment
        if len(assignment) == len(self.variables):
            return assignment

        # Select unassigned variable
        var = self._select_unassigned_variable(assignment)

        # Try each value in domain
        for value in self.domains[var]:
            assignment[var] = value

            if self.is_consistent(assignment):
                result = self._backtrack(assignment)
                if result:
                    return result

            del assignment[var]

        return None

    def _select_unassigned_variable(self, assignment):
        """Select next variable to assign (simple version)"""
        for var in self.variables:
            if var not in assignment:
                return var
        return None
```

### Constraint Propagation

```python
def arc_consistency_3(csp):
    """
    AC-3 algorithm for constraint propagation.

    Reduces domains by enforcing arc consistency.
    """
    from collections import deque

    # Create queue of all arcs
    queue = deque()
    for constraint_fn, vars_involved in csp.constraints:
        for i, var1 in enumerate(vars_involved):
            for var2 in vars_involved[i+1:]:
                queue.append((var1, var2, constraint_fn))
                queue.append((var2, var1, constraint_fn))

    while queue:
        var1, var2, constraint = queue.popleft()

        if _revise(csp, var1, var2, constraint):
            if not csp.domains[var1]:
                return False  # Domain empty, no solution

            # Re-add arcs
            for constraint_fn, vars_involved in csp.constraints:
                if var1 in vars_involved:
                    for var in vars_involved:
                        if var != var1:
                            queue.append((var, var1, constraint_fn))

    return True

def _revise(csp, var1, var2, constraint):
    """Remove values from var1 domain that violate constraint"""
    revised = False
    for value1 in list(csp.domains[var1]):
        # Check if any value2 satisfies constraint
        satisfies = False
        for value2 in csp.domains[var2]:
            if constraint(value1, value2):
                satisfies = True
                break

        if not satisfies:
            csp.domains[var1].remove(value1)
            revised = True

    return revised
```

---

## Planning Domain Definition Languages

### PDDL-Like Representation

```python
class PDDLAction:
    """Action in PDDL-like representation"""

    def __init__(self, name, parameters, preconditions, effects):
        """
        Args:
            name: Action name
            parameters: List of parameter names
            preconditions: List of predicates that must be true
            effects: Dict of {add: [...], delete: [...]}
        """
        self.name = name
        self.parameters = parameters
        self.preconditions = preconditions
        self.effects = effects

    def applicable(self, state):
        """Check if action can be applied in state"""
        return all(p in state for p in self.preconditions)

    def apply(self, state):
        """Apply action to state, returning new state"""
        new_state = state.copy()
        new_state.update(self.effects.get('add', []))
        new_state.difference_update(self.effects.get('delete', []))
        return new_state

    def __repr__(self):
        return f"Action({self.name})"


# Example: Database migration actions
setup_postgres = PDDLAction(
    name="setup_postgres",
    parameters=[],
    preconditions=[],
    effects={
        'add': ['postgres_running'],
        'delete': []
    }
)

migrate_schema = PDDLAction(
    name="migrate_schema",
    parameters=[],
    preconditions=['postgres_running', 'mysql_running'],
    effects={
        'add': ['postgres_schema_ready'],
        'delete': []
    }
)

migrate_data = PDDLAction(
    name="migrate_data",
    parameters=[],
    preconditions=[
        'postgres_schema_ready',
        'mysql_running',
        'data_in_mysql'
    ],
    effects={
        'add': ['data_in_postgres', 'data_synchronized'],
        'delete': []
    }
)

switch_to_postgres = PDDLAction(
    name="switch_to_postgres",
    parameters=[],
    preconditions=['data_synchronized', 'postgres_running'],
    effects={
        'add': ['app_using_postgres'],
        'delete': ['app_using_mysql']
    }
)
```

### Domain Definition

```python
class PlanningDomain:
    """Planning domain with actions and predicates"""

    def __init__(self, name):
        self.name = name
        self.predicates = set()
        self.actions = []

    def add_predicate(self, predicate):
        """Register a predicate"""
        self.predicates.add(predicate)

    def add_action(self, action):
        """Register an action"""
        self.actions.append(action)

    def applicable_actions(self, state):
        """Get actions applicable in state"""
        return [a for a in self.actions if a.applicable(state)]


# Example: Database migration domain
db_migration_domain = PlanningDomain("database_migration")

# Register predicates
for pred in ['mysql_running', 'postgres_running', 'postgres_schema_ready',
             'data_in_mysql', 'data_in_postgres', 'data_synchronized',
             'app_using_mysql', 'app_using_postgres']:
    db_migration_domain.add_predicate(pred)

# Register actions
for action in [setup_postgres, migrate_schema, migrate_data, switch_to_postgres]:
    db_migration_domain.add_action(action)
```

---

## Validation Checklist Templates

### End State Validation Checklist

```yaml
end_state_validation:
  name: "End State SMART Criteria Check"

  specific:
    - question: "Is the goal concrete and unambiguous?"
      guidance: "Avoid vague terms like 'better', 'faster', 'improved'"
    - question: "Are all key aspects of the target state described?"
      guidance: "Architecture, data, performance, security, etc."

  measurable:
    - question: "Are success metrics defined?"
      guidance: "Numeric targets, percentages, counts, boolean criteria"
    - question: "Is the measurement method specified?"
      guidance: "How will we verify we've reached the target?"
    - question: "Are current values known?"
      guidance: "Baseline for comparison"

  achievable:
    - question: "Is the goal technically possible?"
      guidance: "No physically impossible requirements"
    - question: "Are resources available or acquirable?"
      guidance: "Budget, people, infrastructure, time"
    - question: "Are there fewer than 3 blocking constraints?"
      guidance: "Too many blockers suggest infeasibility"

  relevant:
    - question: "Is the goal aligned with business objectives?"
      guidance: "Can trace to business value"
    - question: "Do stakeholders agree this is the right goal?"
      guidance: "Written approval from decision-makers"

  time_bound:
    - question: "Is there a clear deadline?"
      guidance: "Specific date, not 'soon' or 'eventually'"
    - question: "Are intermediate milestones defined?"
      guidance: "Checkpoints to track progress"
```

### Backward Chain Validation Checklist

```yaml
backward_chain_validation:
  name: "Backward Chain Quality Check"

  completeness:
    - question: "Does chain start at current state?"
      required: true
    - question: "Does chain end at goal state?"
      required: true
    - question: "Are all intermediate states necessary?"
      guidance: "No redundant states"
    - question: "Are any states missing?"
      guidance: "Walk through chain, verify no gaps"

  consistency:
    - question: "Does each state have a clear definition?"
      guidance: "State predicates are explicit"
    - question: "Are any states contradictory?"
      guidance: "Check for mutually exclusive properties"
    - question: "Are all states achievable?"
      guidance: "No impossible states"

  transitions:
    - question: "Can each state transition to the next?"
      guidance: "Valid path exists"
    - question: "Are actions defined for each transition?"
      guidance: "Clear what causes state change"
    - question: "Are transition costs estimated?"
      guidance: "Time, resources, risk"

  dependencies:
    - question: "Are dependencies acyclic?"
      required: true
      guidance: "No circular dependencies"
    - question: "Are all prerequisites identified?"
      guidance: "Run prerequisite checklist"
```

### Prerequisite Validation Checklist

```yaml
prerequisite_validation:
  name: "Comprehensive Prerequisite Check"

  technical:
    - "What infrastructure must be in place?"
    - "What tools/libraries are required?"
    - "What APIs/interfaces must exist?"
    - "What technical debt blocks this?"
    - "What compatibility requirements exist?"

  data:
    - "What data must be migrated?"
    - "What schema changes are needed?"
    - "What data quality issues must be resolved?"
    - "What backups are required?"
    - "What data validation is needed?"

  knowledge:
    - "What skills does the team lack?"
    - "What training is required?"
    - "What documentation must exist?"
    - "What subject matter experts are needed?"
    - "What tribal knowledge must be captured?"

  resource:
    - "What budget is required?"
    - "What hardware/infrastructure is needed?"
    - "What licenses must be purchased?"
    - "What staff must be allocated?"
    - "What external resources are needed?"

  organizational:
    - "What approvals are needed?"
    - "What process changes are required?"
    - "What cross-team coordination is needed?"
    - "What communication plans are needed?"
    - "What change management is required?"

  dependency:
    - "What external systems must be ready?"
    - "What third-party services are required?"
    - "What vendor commitments are needed?"
    - "What team dependencies exist?"
    - "What sequencing constraints exist?"

  compliance:
    - "What security reviews are needed?"
    - "What legal approvals are required?"
    - "What regulatory requirements apply?"
    - "What audit requirements exist?"
    - "What privacy requirements apply?"
```

### Feasibility Validation Checklist

```yaml
feasibility_validation:
  name: "Plan Feasibility Assessment"

  state_consistency:
    - "Are any states self-contradictory?"
    - "Are any predicates physically impossible?"
    - "Are all states internally consistent?"

  prerequisite_satisfiability:
    - "Can all blocking prerequisites be satisfied?"
    - "Are resources available for all prerequisites?"
    - "Are skills available or trainable?"
    - "Are dependencies available?"

  constraint_satisfaction:
    - "Is timeline within limits?"
    - "Is cost within budget?"
    - "Is team capacity sufficient?"
    - "Are technical constraints met?"
    - "Are organizational constraints met?"

  risk_assessment:
    - "Are high-risk transitions identified?"
    - "Are mitigation strategies defined?"
    - "Are rollback plans in place?"
    - "Are contingencies planned?"

  validation:
    - "Has the plan been peer-reviewed?"
    - "Have stakeholders approved?"
    - "Has historical data been considered?"
    - "Have experts been consulted?"
```

---

## Gap Analysis Frameworks

### Multi-Dimensional Gap Analysis

```python
class GapAnalysisFramework:
    """Framework for comprehensive gap analysis"""

    DIMENSIONS = {
        'architecture': {
            'attributes': [
                'pattern',
                'components',
                'communication',
                'data_flow',
                'deployment'
            ],
            'weight': 5
        },
        'capabilities': {
            'attributes': [
                'features',
                'performance',
                'reliability',
                'scalability',
                'security'
            ],
            'weight': 5
        },
        'data': {
            'attributes': [
                'schema',
                'volume',
                'quality',
                'governance',
                'migration'
            ],
            'weight': 4
        },
        'infrastructure': {
            'attributes': [
                'hosting',
                'networking',
                'monitoring',
                'logging',
                'alerting'
            ],
            'weight': 4
        },
        'skills': {
            'attributes': [
                'technical_skills',
                'domain_knowledge',
                'tooling',
                'processes',
                'culture'
            ],
            'weight': 3
        },
        'process': {
            'attributes': [
                'development',
                'testing',
                'deployment',
                'operations',
                'incident_response'
            ],
            'weight': 3
        },
        'security': {
            'attributes': [
                'authentication',
                'authorization',
                'encryption',
                'compliance',
                'audit'
            ],
            'weight': 4
        },
        'compliance': {
            'attributes': [
                'regulatory',
                'legal',
                'privacy',
                'audit',
                'reporting'
            ],
            'weight': 3
        }
    }

    def analyze(self, current, target):
        """
        Analyze gaps across all dimensions.

        Returns: Dict of {dimension: gap_analysis}
        """
        results = {}

        for dimension, config in self.DIMENSIONS.items():
            current_attrs = current.get(dimension, {})
            target_attrs = target.get(dimension, {})

            results[dimension] = {
                'missing': self._find_missing(
                    current_attrs,
                    target_attrs,
                    config['attributes']
                ),
                'obsolete': self._find_obsolete(
                    current_attrs,
                    target_attrs,
                    config['attributes']
                ),
                'severity': self._calculate_severity(
                    current_attrs,
                    target_attrs,
                    config['weight']
                ),
                'effort': self._estimate_effort(
                    current_attrs,
                    target_attrs
                )
            }

        return results

    def _find_missing(self, current, target, attributes):
        """Find attributes present in target but missing in current"""
        missing = []
        for attr in attributes:
            if target.get(attr) and not current.get(attr):
                missing.append({
                    'attribute': attr,
                    'target_value': target[attr],
                    'priority': self._prioritize_gap(attr, target[attr])
                })
        return missing

    def _find_obsolete(self, current, target, attributes):
        """Find attributes in current that should be removed"""
        obsolete = []
        for attr in attributes:
            if current.get(attr) and not target.get(attr):
                obsolete.append({
                    'attribute': attr,
                    'current_value': current[attr],
                    'migration_needed': True
                })
        return obsolete

    def _calculate_severity(self, current, target, weight):
        """Calculate gap severity"""
        # Simplified: count of gaps * dimension weight
        gap_count = sum(
            1 for attr in target
            if target[attr] != current.get(attr)
        )
        severity_score = gap_count * weight

        if severity_score > 15:
            return 'critical'
        elif severity_score > 10:
            return 'high'
        elif severity_score > 5:
            return 'medium'
        else:
            return 'low'

    def _estimate_effort(self, current, target):
        """Estimate effort to close gap (person-weeks)"""
        # Simplified effort model
        effort_map = {
            'architecture': 4,
            'capabilities': 3,
            'data': 5,
            'infrastructure': 2,
            'skills': 1,
            'process': 1,
            'security': 3,
            'compliance': 2
        }
        # Count gaps and multiply by effort factor
        gap_count = sum(
            1 for attr in target
            if target[attr] != current.get(attr)
        )
        return gap_count * effort_map.get('default', 2)

    def _prioritize_gap(self, attribute, value):
        """Determine priority of closing gap"""
        critical_attrs = [
            'security',
            'data_integrity',
            'compliance',
            'authentication'
        ]
        if attribute in critical_attrs:
            return 'high'
        return 'medium'
```

---

## Migration Pattern Catalog

### Pattern: Strangler Fig

```python
class StranglerFigPattern:
    """
    Gradually replace legacy system by routing traffic to new system.

    Phases:
    1. Identify seam in legacy system
    2. Implement new functionality in new system
    3. Route requests to new system
    4. Incrementally migrate remaining functionality
    5. Decommission legacy when empty
    """

    @staticmethod
    def backward_chain(current, target):
        """Generate backward chain for strangler fig"""
        return [
            {
                'state': 'Legacy Only',
                'predicates': ['legacy_handles_all_traffic'],
                'phase': 0
            },
            {
                'state': 'API Gateway Deployed',
                'predicates': [
                    'api_gateway_routing',
                    'legacy_handles_all_traffic'
                ],
                'phase': 1
            },
            {
                'state': 'First Feature Migrated',
                'predicates': [
                    'api_gateway_routing',
                    'new_system_handles_feature_a',
                    'legacy_handles_rest'
                ],
                'phase': 2
            },
            {
                'state': 'Progressive Migration',
                'predicates': [
                    'api_gateway_routing',
                    'new_system_handles_most',
                    'legacy_handles_few'
                ],
                'phase': 3
            },
            {
                'state': 'Migration Complete',
                'predicates': [
                    'new_system_handles_all_traffic',
                    'legacy_decommissioned'
                ],
                'phase': 4
            }
        ]

    @staticmethod
    def prerequisites():
        """Key prerequisites for strangler fig"""
        return [
            {
                'type': 'technical',
                'desc': 'API gateway supports routing rules',
                'critical': True
            },
            {
                'type': 'technical',
                'desc': 'Can identify seams in legacy system',
                'critical': True
            },
            {
                'type': 'technical',
                'desc': 'Feature parity can be verified',
                'critical': True
            },
            {
                'type': 'organizational',
                'desc': 'Gradual rollout acceptable to stakeholders',
                'critical': True
            }
        ]
```

### Pattern: Parallel Run

```python
class ParallelRunPattern:
    """
    Run old and new systems simultaneously, compare outputs.

    Phases:
    1. Deploy new system alongside old
    2. Duplicate traffic to both
    3. Compare outputs, fix discrepancies
    4. Increase confidence, switch traffic
    5. Decommission old system
    """

    @staticmethod
    def backward_chain(current, target):
        """Generate backward chain for parallel run"""
        return [
            {
                'state': 'Old System Only',
                'predicates': ['old_system_handles_traffic'],
                'phase': 0
            },
            {
                'state': 'New System Deployed',
                'predicates': [
                    'old_system_handles_traffic',
                    'new_system_idle'
                ],
                'phase': 1
            },
            {
                'state': 'Dual Processing',
                'predicates': [
                    'old_system_handles_traffic',
                    'new_system_shadowing',
                    'outputs_compared'
                ],
                'phase': 2
            },
            {
                'state': 'High Confidence',
                'predicates': [
                    'old_system_handles_traffic',
                    'new_system_shadowing',
                    'outputs_match_99_percent'
                ],
                'phase': 3
            },
            {
                'state': 'Traffic Switched',
                'predicates': [
                    'new_system_handles_traffic',
                    'old_system_on_standby'
                ],
                'phase': 4
            },
            {
                'state': 'Old System Decommissioned',
                'predicates': [
                    'new_system_handles_traffic',
                    'old_system_decommissioned'
                ],
                'phase': 5
            }
        ]
```

### Pattern: Blue-Green Deployment

```python
class BlueGreenPattern:
    """
    Maintain two identical production environments, switch atomically.

    Phases:
    1. Blue (current) handles production
    2. Deploy new version to Green
    3. Test Green thoroughly
    4. Switch traffic from Blue to Green
    5. Keep Blue as rollback option
    """

    @staticmethod
    def backward_chain(current, target):
        """Generate backward chain for blue-green"""
        return [
            {
                'state': 'Blue Active',
                'predicates': [
                    'blue_deployed_v1',
                    'green_idle',
                    'traffic_to_blue'
                ],
                'phase': 0
            },
            {
                'state': 'Green Deployed',
                'predicates': [
                    'blue_deployed_v1',
                    'green_deployed_v2',
                    'traffic_to_blue'
                ],
                'phase': 1
            },
            {
                'state': 'Green Tested',
                'predicates': [
                    'blue_deployed_v1',
                    'green_deployed_v2',
                    'green_tests_passing',
                    'traffic_to_blue'
                ],
                'phase': 2
            },
            {
                'state': 'Traffic Switched',
                'predicates': [
                    'blue_deployed_v1',
                    'green_deployed_v2',
                    'traffic_to_green'
                ],
                'phase': 3
            },
            {
                'state': 'Blue Redeployed',
                'predicates': [
                    'blue_deployed_v2',
                    'green_deployed_v2',
                    'traffic_to_green'
                ],
                'phase': 4
            }
        ]
```

---

## API Documentation

### Core Classes

```python
# End State Definition
class EndStateDefinition:
    def __init__(self, name: str, description: str)
    def add_metric(self, name: str, current: float, target: float, unit: str)
    def add_constraint(self, type: str, description: str, is_blocking: bool)
    def validate_smart(self) -> tuple[bool, List[str]]
    def to_json(self, filepath: str)
    @classmethod
    def from_json(cls, filepath: str) -> 'EndStateDefinition'

# Backward Chainer
class BackwardChainer:
    def __init__(self)
    def add_transition(self, transition: Transition)
    def build_chain(self, current: State, goal: State) -> Optional[List[State]]

# Prerequisite Detector
class PrerequisiteDetector:
    def __init__(self)
    def detect_for_transition(
        self,
        from_predicates: Set[str],
        to_predicates: Set[str],
        transition_name: str
    ) -> List[Prerequisite]

# Feasibility Checker
class FeasibilityChecker:
    def __init__(self, constraints: Constraints)
    def check_chain(
        self,
        chain: List[Dict],
        transitions: List[Dict],
        prerequisites: Dict[str, List[Dict]]
    ) -> tuple[bool, List[FeasibilityIssue]]

# Gap Analyzer
class GapAnalyzer:
    def __init__(self, current_state, target_state)
    def analyze_all(self) -> Dict[str, Dict]
    def prioritize_gaps(self) -> List[Dict]
```

### Command-Line Interface

```bash
# Define end state
python -m work_backcasting.define_end_state \
  --name "Migration Complete" \
  --description "PostgreSQL migration with zero data loss" \
  --output end_state.json

# Build backward chain
python -m work_backcasting.backward_chain \
  --current current_state.json \
  --target end_state.json \
  --output chain.json

# Identify prerequisites
python -m work_backcasting.prerequisites \
  --chain chain.json \
  --output prereqs.json

# Check feasibility
python -m work_backcasting.feasibility \
  --chain chain.json \
  --prerequisites prereqs.json \
  --constraints constraints.yaml \
  --output feasibility_report.json

# Gap analysis
python -m work_backcasting.gap_analysis \
  --current current_state.json \
  --target end_state.json \
  --output gaps.json

# Generate execution plan
python -m work_backcasting.execution_plan \
  --chain chain.json \
  --prerequisites prereqs.json \
  --gaps gaps.json \
  --output roadmap.md
```

---

## Quick Reference Tables

### Complexity Estimation

| Factor | Low (1x) | Medium (1.5x) | High (2x) | Very High (3x) |
|--------|----------|---------------|-----------|----------------|
| Technical Unknowns | 0-1 | 2-3 | 4-6 | 7+ |
| Dependencies | 0-2 | 3-5 | 6-10 | 11+ |
| Team Experience | Expert | Proficient | Learning | New |
| System Complexity | Simple | Moderate | Complex | Very Complex |

### Risk Levels

| Risk Score | Level | Action |
|------------|-------|--------|
| 0-3 | LOW | Proceed with standard oversight |
| 4-6 | MEDIUM | Add extra monitoring and checkpoints |
| 7-9 | HIGH | Require approval, add contingencies |
| 10+ | CRITICAL | Re-evaluate, possibly redesign |

### Effort Multipliers

| Confidence Level | Multiplier | Range |
|------------------|------------|-------|
| High | 1.0x | 0.8x - 1.2x |
| Medium | 1.5x | 0.6x - 2.5x |
| Low | 2.0x | 0.25x - 4.0x |
| Very Low | 3.0x | 0.1x - 10.0x |

---

## Further Reading

- **Books**:
  - "Artificial Intelligence: A Modern Approach" - Russell & Norvig
  - "Automated Planning: Theory and Practice" - Ghallab, Nau, Traverso
  - "Building Microservices" - Sam Newman
  - "Continuous Delivery" - Humble & Farley

- **Papers**:
  - Robinson (1982): "Energy backcasting: A proposed method"
  - Fikes & Nilsson (1971): "STRIPS planning"
  - Newell & Simon (1972): "Human Problem Solving"

- **Online**:
  - Planning.domains: PDDL resources
  - Fast Downward: Planning system
  - Martin Fowler's refactoring catalog
