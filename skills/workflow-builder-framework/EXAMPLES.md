# Workflow Examples

Complete working examples demonstrating workflow patterns in real-world scenarios.

## Example 1: Multi-Agent Data Pipeline (DAG)

A data processing pipeline that fetches data from multiple sources, processes it, and stores results.

```python
from workflow_builder import DAGWorkflow, Task
import requests
import pandas as pd
from typing import Dict, Any

class DataPipeline:
    def __init__(self):
        self.workflow = DAGWorkflow()

    def build_pipeline(self):
        """Build data processing DAG"""
        # Fetch from multiple sources in parallel
        self.workflow.add_task("fetch_api1", self._fetch_api1)
        self.workflow.add_task("fetch_api2", self._fetch_api2)
        self.workflow.add_task("fetch_db", self._fetch_db)

        # Validate each source
        self.workflow.add_task("validate_api1", self._validate, depends_on=["fetch_api1"])
        self.workflow.add_task("validate_api2", self._validate, depends_on=["fetch_api2"])
        self.workflow.add_task("validate_db", self._validate, depends_on=["fetch_db"])

        # Merge all validated data
        self.workflow.add_task(
            "merge",
            self._merge_data,
            depends_on=["validate_api1", "validate_api2", "validate_db"]
        )

        # Transform merged data
        self.workflow.add_task("transform", self._transform, depends_on=["merge"])

        # Save to multiple destinations in parallel
        self.workflow.add_task("save_warehouse", self._save_warehouse, depends_on=["transform"])
        self.workflow.add_task("save_cache", self._save_cache, depends_on=["transform"])
        self.workflow.add_task("save_analytics", self._save_analytics, depends_on=["transform"])

        # Send notification when all saves complete
        self.workflow.add_task(
            "notify",
            self._send_notification,
            depends_on=["save_warehouse", "save_cache", "save_analytics"]
        )

    def _fetch_api1(self) -> Dict:
        """Fetch from API 1"""
        response = requests.get("https://api1.example.com/data")
        return {"source": "api1", "data": response.json()}

    def _fetch_api2(self) -> Dict:
        """Fetch from API 2"""
        response = requests.get("https://api2.example.com/data")
        return {"source": "api2", "data": response.json()}

    def _fetch_db(self) -> Dict:
        """Fetch from database"""
        # Simulate DB query
        return {"source": "db", "data": [{"id": 1, "value": 100}]}

    def _validate(self, **kwargs) -> Dict:
        """Validate data from any source"""
        for source_data in kwargs.values():
            if not source_data.get("data"):
                raise ValueError(f"Invalid data from {source_data['source']}")
        return kwargs

    def _merge_data(self, validate_api1, validate_api2, validate_db) -> pd.DataFrame:
        """Merge data from all sources"""
        all_data = []
        for source in [validate_api1, validate_api2, validate_db]:
            for key, val in source.items():
                all_data.extend(val["data"])
        return pd.DataFrame(all_data)

    def _transform(self, merge: pd.DataFrame) -> pd.DataFrame:
        """Transform data"""
        # Apply transformations
        merge["processed_at"] = pd.Timestamp.now()
        return merge

    def _save_warehouse(self, transform: pd.DataFrame) -> str:
        """Save to data warehouse"""
        # Simulate warehouse save
        return f"warehouse_batch_{pd.Timestamp.now().strftime('%Y%m%d_%H%M%S')}"

    def _save_cache(self, transform: pd.DataFrame) -> bool:
        """Save to cache"""
        # Simulate cache save
        return True

    def _save_analytics(self, transform: pd.DataFrame) -> str:
        """Save to analytics platform"""
        # Simulate analytics save
        return "analytics_batch_123"

    def _send_notification(self, save_warehouse, save_cache, save_analytics) -> None:
        """Send completion notification"""
        print(f"Pipeline complete!")
        print(f"  - Warehouse: {save_warehouse}")
        print(f"  - Cache: {save_cache}")
        print(f"  - Analytics: {save_analytics}")

    def run(self):
        """Execute pipeline"""
        self.build_pipeline()
        results = self.workflow.execute(max_parallel=4)
        return results

# Usage
if __name__ == "__main__":
    pipeline = DataPipeline()
    results = pipeline.run()
```

---

## Example 2: Deployment Workflow with Rollback (State Machine)

A deployment pipeline with stages, approval gates, and automatic rollback on failure.

```python
from workflow_builder import StateMachine
from typing import Dict, Any
import time

class DeploymentWorkflow:
    def __init__(self, environment: str):
        self.environment = environment
        self.context = {
            "build_id": None,
            "tests_passed": False,
            "approved": False,
            "health_check_passed": False,
            "previous_version": None,
            "deployment_url": None
        }
        self.fsm = StateMachine("idle", context=self.context)
        self._build_state_machine()

    def _build_state_machine(self):
        """Define deployment state machine"""
        # Initial -> Building
        self.fsm.add_transition(
            "idle", "building", "start",
            action=self._start_build
        )

        # Building -> Testing
        self.fsm.add_transition(
            "building", "testing", "build_complete",
            action=self._run_tests
        )

        # Testing -> Awaiting Approval (if tests pass)
        self.fsm.add_transition(
            "testing", "awaiting_approval", "tests_passed",
            guard=lambda ctx: ctx["tests_passed"]
        )

        # Testing -> Failed (if tests fail)
        self.fsm.add_transition(
            "testing", "failed", "tests_failed",
            guard=lambda ctx: not ctx["tests_passed"]
        )

        # Awaiting Approval -> Deploying
        self.fsm.add_transition(
            "awaiting_approval", "deploying", "approve",
            guard=lambda ctx: ctx["approved"],
            action=self._deploy
        )

        # Deploying -> Health Check
        self.fsm.add_transition(
            "deploying", "health_check", "deployment_complete",
            action=self._check_health
        )

        # Health Check -> Live (if healthy)
        self.fsm.add_transition(
            "health_check", "live", "health_check_passed",
            guard=lambda ctx: ctx["health_check_passed"],
            action=self._mark_live
        )

        # Health Check -> Rolling Back (if unhealthy)
        self.fsm.add_transition(
            "health_check", "rolling_back", "health_check_failed",
            guard=lambda ctx: not ctx["health_check_passed"],
            action=self._start_rollback
        )

        # Rolling Back -> Rolled Back
        self.fsm.add_transition(
            "rolling_back", "rolled_back", "rollback_complete",
            action=self._complete_rollback
        )

        # Emergency rollback from any state
        self.fsm.add_transition(
            "*", "rolling_back", "emergency_rollback",
            action=self._start_rollback
        )

    def _start_build(self, ctx: Dict):
        """Start build process"""
        print("Starting build...")
        time.sleep(1)
        ctx["build_id"] = f"build-{int(time.time())}"
        ctx["previous_version"] = "v1.2.3"
        print(f"  Build ID: {ctx['build_id']}")

    def _run_tests(self, ctx: Dict):
        """Run test suite"""
        print("Running tests...")
        time.sleep(2)
        # Simulate test results
        ctx["tests_passed"] = True
        print(f"  Tests: {'PASSED' if ctx['tests_passed'] else 'FAILED'}")

    def _deploy(self, ctx: Dict):
        """Deploy to environment"""
        print(f"Deploying to {self.environment}...")
        time.sleep(2)
        ctx["deployment_url"] = f"https://{self.environment}.example.com"
        print(f"  Deployed to: {ctx['deployment_url']}")

    def _check_health(self, ctx: Dict):
        """Check deployment health"""
        print("Running health checks...")
        time.sleep(1)
        # Simulate health check
        ctx["health_check_passed"] = True
        print(f"  Health: {'HEALTHY' if ctx['health_check_passed'] else 'UNHEALTHY'}")

    def _mark_live(self, ctx: Dict):
        """Mark deployment as live"""
        print(f"Deployment is now LIVE!")
        print(f"  URL: {ctx['deployment_url']}")

    def _start_rollback(self, ctx: Dict):
        """Start rollback process"""
        print("ROLLBACK INITIATED!")
        print(f"  Rolling back to: {ctx['previous_version']}")
        time.sleep(2)

    def _complete_rollback(self, ctx: Dict):
        """Complete rollback"""
        print("Rollback complete")
        print(f"  Active version: {ctx['previous_version']}")

    def execute_deployment(self):
        """Execute deployment workflow"""
        print(f"=== Deploying to {self.environment} ===\n")

        # Start deployment
        self.fsm.trigger("start")
        self.fsm.trigger("build_complete")

        # Tests passed, awaiting approval
        self.fsm.trigger("tests_passed")

        # Manual approval (simulate)
        print("\nAwaiting approval...")
        time.sleep(1)
        self.context["approved"] = True
        self.fsm.trigger("approve")

        # Deploy and health check
        self.fsm.trigger("deployment_complete")

        # Check health status
        if self.context["health_check_passed"]:
            self.fsm.trigger("health_check_passed")
        else:
            self.fsm.trigger("health_check_failed")
            self.fsm.trigger("rollback_complete")

        print(f"\nFinal state: {self.fsm.current_state}")
        print(f"State history: {' -> '.join(self.fsm.history)}")

# Usage
if __name__ == "__main__":
    deployment = DeploymentWorkflow("production")
    deployment.execute_deployment()
```

---

## Example 3: Reactive Event System (Event-Driven)

A reactive system that processes events asynchronously with event sourcing.

```python
from workflow_builder import EventDrivenWorkflow, Event
import time
from typing import Dict, Any

class OrderProcessingSystem:
    def __init__(self):
        self.workflow = EventDrivenWorkflow()
        self._register_handlers()

    def _register_handlers(self):
        """Register all event handlers"""
        # Order lifecycle
        self.workflow.on_event("order.created")(self._on_order_created)
        self.workflow.on_event("payment.requested")(self._on_payment_requested)
        self.workflow.on_event("payment.completed")(self._on_payment_completed)
        self.workflow.on_event("payment.failed")(self._on_payment_failed)
        self.workflow.on_event("inventory.reserved")(self._on_inventory_reserved)
        self.workflow.on_event("inventory.unavailable")(self._on_inventory_unavailable)
        self.workflow.on_event("shipment.created")(self._on_shipment_created)
        self.workflow.on_event("order.completed")(self._on_order_completed)
        self.workflow.on_event("order.cancelled")(self._on_order_cancelled)

    def _on_order_created(self, event: Event):
        """Handle order creation"""
        order_id = event.data["order_id"]
        print(f"[{event.timestamp}] Order created: {order_id}")

        # Request payment
        self.workflow.emit("payment.requested", {
            "order_id": order_id,
            "amount": event.data["amount"]
        })

    def _on_payment_requested(self, event: Event):
        """Handle payment request"""
        order_id = event.data["order_id"]
        amount = event.data["amount"]
        print(f"  Processing payment: ${amount} for order {order_id}")

        # Simulate payment processing
        time.sleep(0.5)
        success = True  # Simulate success

        if success:
            self.workflow.emit("payment.completed", {
                "order_id": order_id,
                "payment_id": f"pay-{int(time.time())}"
            })
        else:
            self.workflow.emit("payment.failed", {
                "order_id": order_id,
                "reason": "Insufficient funds"
            })

    def _on_payment_completed(self, event: Event):
        """Handle payment completion"""
        order_id = event.data["order_id"]
        payment_id = event.data["payment_id"]
        print(f"  Payment completed: {payment_id}")

        # Reserve inventory
        self.workflow.emit("inventory.check", {
            "order_id": order_id,
            "items": ["item1", "item2"]
        })

    def _on_payment_failed(self, event: Event):
        """Handle payment failure"""
        order_id = event.data["order_id"]
        print(f"  Payment FAILED for order {order_id}")

        # Cancel order
        self.workflow.emit("order.cancelled", {
            "order_id": order_id,
            "reason": event.data["reason"]
        })

    def _on_inventory_reserved(self, event: Event):
        """Handle inventory reservation"""
        order_id = event.data["order_id"]
        print(f"  Inventory reserved for order {order_id}")

        # Create shipment
        self.workflow.emit("shipment.create", {
            "order_id": order_id,
            "items": event.data["items"]
        })

    def _on_inventory_unavailable(self, event: Event):
        """Handle inventory unavailability"""
        order_id = event.data["order_id"]
        print(f"  Inventory UNAVAILABLE for order {order_id}")

        # Refund and cancel
        self.workflow.emit("payment.refund", {"order_id": order_id})
        self.workflow.emit("order.cancelled", {
            "order_id": order_id,
            "reason": "Inventory unavailable"
        })

    def _on_shipment_created(self, event: Event):
        """Handle shipment creation"""
        order_id = event.data["order_id"]
        tracking = event.data["tracking_number"]
        print(f"  Shipment created: {tracking}")

        # Complete order
        self.workflow.emit("order.completed", {
            "order_id": order_id,
            "tracking_number": tracking
        })

    def _on_order_completed(self, event: Event):
        """Handle order completion"""
        order_id = event.data["order_id"]
        print(f"[SUCCESS] Order completed: {order_id}")

    def _on_order_cancelled(self, event: Event):
        """Handle order cancellation"""
        order_id = event.data["order_id"]
        reason = event.data["reason"]
        print(f"[CANCELLED] Order {order_id}: {reason}")

    def create_order(self, order_id: str, amount: float):
        """Create new order"""
        self.workflow.emit("order.created", {
            "order_id": order_id,
            "amount": amount,
            "customer_id": "cust-123"
        })

# Usage
if __name__ == "__main__":
    system = OrderProcessingSystem()

    # Create orders
    system.create_order("order-001", 99.99)
    time.sleep(2)
    system.create_order("order-002", 149.99)
```

---

## Example 4: Distributed Transaction (Saga)

An e-commerce checkout saga with compensation logic.

```python
from workflow_builder import SagaOrchestrator
import time

class CheckoutSaga:
    def __init__(self, order_data: dict):
        self.order_data = order_data
        self.saga = SagaOrchestrator("CheckoutSaga")
        self._build_saga()

    def _build_saga(self):
        """Build checkout saga with compensation"""
        # Step 1: Reserve inventory
        self.saga.add_step(
            "reserve_inventory",
            forward=self._reserve_inventory,
            compensate=self._release_inventory
        )

        # Step 2: Process payment
        self.saga.add_step(
            "process_payment",
            forward=self._process_payment,
            compensate=self._refund_payment
        )

        # Step 3: Create shipment
        self.saga.add_step(
            "create_shipment",
            forward=self._create_shipment,
            compensate=self._cancel_shipment
        )

        # Step 4: Send confirmation
        self.saga.add_step(
            "send_confirmation",
            forward=self._send_confirmation,
            compensate=self._send_cancellation
        )

    def _reserve_inventory(self):
        """Reserve inventory"""
        print("Step 1: Reserving inventory...")
        time.sleep(0.5)
        return {"reservation_id": "res-123", "items": self.order_data["items"]}

    def _release_inventory(self):
        """Compensate: Release inventory"""
        print("  Compensation: Releasing inventory")
        time.sleep(0.3)

    def _process_payment(self):
        """Process payment"""
        print("Step 2: Processing payment...")
        time.sleep(0.5)

        # Simulate occasional failure
        if self.order_data.get("fail_payment"):
            raise Exception("Payment declined")

        return {"payment_id": "pay-456", "amount": self.order_data["amount"]}

    def _refund_payment(self):
        """Compensate: Refund payment"""
        print("  Compensation: Refunding payment")
        time.sleep(0.3)

    def _create_shipment(self):
        """Create shipment"""
        print("Step 3: Creating shipment...")
        time.sleep(0.5)
        return {"shipment_id": "ship-789", "tracking": "TRACK123"}

    def _cancel_shipment(self):
        """Compensate: Cancel shipment"""
        print("  Compensation: Canceling shipment")
        time.sleep(0.3)

    def _send_confirmation(self):
        """Send confirmation email"""
        print("Step 4: Sending confirmation email...")
        time.sleep(0.3)
        return {"email_sent": True}

    def _send_cancellation(self):
        """Compensate: Send cancellation email"""
        print("  Compensation: Sending cancellation email")
        time.sleep(0.3)

    def execute(self):
        """Execute saga"""
        try:
            results = self.saga.execute()
            print(f"\nCheckout successful!")
            return results
        except Exception as e:
            print(f"\nCheckout failed and compensated")
            raise

# Usage
if __name__ == "__main__":
    # Successful checkout
    print("=== Successful Checkout ===")
    order1 = {
        "order_id": "order-001",
        "items": ["item1", "item2"],
        "amount": 99.99
    }
    saga1 = CheckoutSaga(order1)
    saga1.execute()

    print("\n" + "="*50 + "\n")

    # Failed checkout (payment fails)
    print("=== Failed Checkout (Payment Declined) ===")
    order2 = {
        "order_id": "order-002",
        "items": ["item3"],
        "amount": 49.99,
        "fail_payment": True  # Trigger failure
    }
    saga2 = CheckoutSaga(order2)
    try:
        saga2.execute()
    except Exception:
        pass
```

---

## Example 5: Complete Workflow with Observability

A comprehensive workflow demonstrating error handling, retry logic, circuit breakers, and full observability.

```python
from workflow_builder import (
    DAGWorkflow, Task, RetryStrategy, CircuitBreaker,
    Tracer, MetricsCollector, StructuredLogger
)
import time
import random

class ObservableWorkflow:
    def __init__(self):
        self.workflow = DAGWorkflow()
        self.tracer = Tracer()
        self.metrics = MetricsCollector()
        self.logger = StructuredLogger()
        self.circuit = CircuitBreaker(failure_threshold=3)

    def build_workflow(self):
        """Build workflow with observability"""
        # Fetch data
        self.workflow.add_task("fetch", self._fetch_with_observability)

        # Process data
        self.workflow.add_task("process", self._process_with_observability, depends_on=["fetch"])

        # Save results
        self.workflow.add_task("save", self._save_with_observability, depends_on=["process"])

    def _fetch_with_observability(self):
        """Fetch data with full observability"""
        with self.tracer.start_span("fetch_data", {"source": "api"}) as span:
            self.metrics.increment("fetch.attempts")
            self.logger.log("INFO", "Fetching data", source="api")

            start = time.time()

            try:
                # Retry with exponential backoff
                result = RetryStrategy.exponential_backoff(
                    lambda: self.circuit.call(self._unreliable_fetch),
                    max_attempts=3
                )

                duration = time.time() - start
                self.metrics.histogram("fetch.duration_ms", duration * 1000)
                self.metrics.increment("fetch.success")

                span.attributes["records_fetched"] = len(result)
                self.logger.log("INFO", "Fetch successful", records=len(result))

                return result

            except Exception as e:
                self.metrics.increment("fetch.errors")
                self.logger.log("ERROR", "Fetch failed", error=str(e))
                raise

    def _unreliable_fetch(self):
        """Simulate unreliable API"""
        if random.random() < 0.3:  # 30% failure rate
            raise Exception("API timeout")
        return [{"id": i, "value": random.randint(1, 100)} for i in range(10)]

    def _process_with_observability(self, fetch):
        """Process data with observability"""
        with self.tracer.start_span("process_data", {"records": len(fetch)}) as span:
            self.metrics.increment("process.attempts")
            self.logger.log("INFO", "Processing data", records=len(fetch))

            start = time.time()

            # Process records
            processed = []
            for record in fetch:
                processed.append({
                    "id": record["id"],
                    "value": record["value"] * 2,
                    "processed_at": time.time()
                })

            duration = time.time() - start
            self.metrics.histogram("process.duration_ms", duration * 1000)
            self.metrics.gauge("process.records_per_second", len(fetch) / duration)
            self.metrics.increment("process.success")

            span.attributes["records_processed"] = len(processed)
            self.logger.log("INFO", "Processing complete", records=len(processed))

            return processed

    def _save_with_observability(self, process):
        """Save data with observability"""
        with self.tracer.start_span("save_data", {"records": len(process)}) as span:
            self.metrics.increment("save.attempts")
            self.logger.log("INFO", "Saving data", records=len(process))

            start = time.time()

            # Simulate save
            time.sleep(0.5)
            batch_id = f"batch-{int(time.time())}"

            duration = time.time() - start
            self.metrics.histogram("save.duration_ms", duration * 1000)
            self.metrics.increment("save.success")

            span.attributes["batch_id"] = batch_id
            self.logger.log("INFO", "Save complete", batch_id=batch_id)

            return {"batch_id": batch_id, "records": len(process)}

    def execute(self):
        """Execute workflow with observability"""
        print("=== Executing Workflow ===\n")

        with self.tracer.start_span("workflow.execute") as root_span:
            start = time.time()

            try:
                self.build_workflow()
                result = self.workflow.execute()

                duration = time.time() - start
                self.metrics.histogram("workflow.duration_ms", duration * 1000)
                self.metrics.increment("workflow.success")

                root_span.attributes["result"] = result

                print("\n=== Workflow Complete ===")
                self._print_metrics()
                self._print_traces()

                return result

            except Exception as e:
                self.metrics.increment("workflow.errors")
                self.logger.log("ERROR", "Workflow failed", error=str(e))
                raise

    def _print_metrics(self):
        """Print collected metrics"""
        print("\n--- Metrics ---")
        print(f"Counters: {self.metrics.metrics['counters']}")
        print(f"Gauges: {self.metrics.metrics['gauges']}")
        for name, values in self.metrics.metrics['histograms'].items():
            print(f"{name}: min={min(values):.2f}, max={max(values):.2f}, avg={sum(values)/len(values):.2f}")

    def _print_traces(self):
        """Print trace data"""
        print("\n--- Traces ---")
        for span_id, span in self.tracer.spans.items():
            indent = "  " * (1 if span.parent_id else 0)
            print(f"{indent}{span.name}: {span.duration()*1000:.2f}ms [{span.status}]")
            if span.attributes:
                for key, value in span.attributes.items():
                    print(f"{indent}  - {key}: {value}")

# Usage
if __name__ == "__main__":
    workflow = ObservableWorkflow()
    try:
        result = workflow.execute()
        print(f"\nFinal result: {result}")
    except Exception as e:
        print(f"\nWorkflow failed: {e}")
```

---

## Real-World Use Cases

### Use Case 1: CI/CD Pipeline

Combining DAG and State Machine patterns for a complete CI/CD workflow.

```python
# Build -> Test -> Deploy pipeline
pipeline = DAGWorkflow()
pipeline.add_task("checkout", checkout_code)
pipeline.add_task("install_deps", install_dependencies, depends_on=["checkout"])
pipeline.add_task("lint", run_linter, depends_on=["install_deps"])
pipeline.add_task("unit_tests", run_unit_tests, depends_on=["install_deps"])
pipeline.add_task("integration_tests", run_integration_tests, depends_on=["unit_tests"])
pipeline.add_task("build", build_artifacts, depends_on=["lint", "integration_tests"])
pipeline.add_task("deploy_staging", deploy_to_staging, depends_on=["build"])
pipeline.add_task("smoke_tests", run_smoke_tests, depends_on=["deploy_staging"])
pipeline.add_task("deploy_prod", deploy_to_production, depends_on=["smoke_tests"])
```

### Use Case 2: Data Processing Pipeline

Processing large datasets with parallelization and error handling.

```python
# Extract, Transform, Load with parallel processing
etl = DAGWorkflow()
etl.add_task("extract_source1", extract_from_db1)
etl.add_task("extract_source2", extract_from_api)
etl.add_task("extract_source3", extract_from_files)
etl.add_task("transform1", transform_db_data, depends_on=["extract_source1"])
etl.add_task("transform2", transform_api_data, depends_on=["extract_source2"])
etl.add_task("transform3", transform_file_data, depends_on=["extract_source3"])
etl.add_task("merge", merge_datasets, depends_on=["transform1", "transform2", "transform3"])
etl.add_task("load_warehouse", load_to_warehouse, depends_on=["merge"])
etl.add_task("update_catalog", update_data_catalog, depends_on=["load_warehouse"])
```

### Use Case 3: Multi-Agent Code Review

Orchestrating multiple AI agents for comprehensive code review.

```python
# Multi-agent review workflow
review = DAGWorkflow()
review.add_task("fetch_pr", fetch_pull_request)
review.add_task("security_scan", security_agent_scan, depends_on=["fetch_pr"])
review.add_task("style_check", style_agent_check, depends_on=["fetch_pr"])
review.add_task("complexity_analysis", complexity_agent_analyze, depends_on=["fetch_pr"])
review.add_task("test_coverage", test_agent_verify, depends_on=["fetch_pr"])
review.add_task("aggregate_feedback", aggregate_results,
                depends_on=["security_scan", "style_check", "complexity_analysis", "test_coverage"])
review.add_task("post_review", post_review_comments, depends_on=["aggregate_feedback"])
```
