# Forms & Templates (canonical, copy-paste)

> Use these canonical shapes to avoid duplication. Keep node files ≤3KB; reference other nodes by `id`.

## InteractionSpec (compact, required fields)
```json
{
  "id":"ix:<slug>", "type":"InteractionSpec",
  "method":"Service.method()", "interface":"<Dependency>", "operation":"<Action>",
  "state":{"factor":"value"},
  "pre":["..."],
  "in":{"params":"...","headers":["..."],"body?":"..."},
  "eff":["state changes","events","cache invalidations"],
  "err":{"retriable":["..."],"non_retriable":["..."],"compensation":["..."]},
  "res":{"timeout_ms":8000,"retry":{"strategy":"exp","max":4,"jitter":true},"idem_key?":"..."},
  "obs":{"logs":["..."],"metrics":["..."],"span":"..."},
  "sec":{"authZ":"...","least_priv":"...","pii":false},
  "test":{"mocks":["..."],"acc":["Given/When/Then ..."]},
  "depends_on":["contract:...","policy:..."],
  "owner":"<team>","est_h":1,"status":"Open"
}
```

## ChangeSpec (wraps interactions)
```json
{
  "id":"change:<slug>", "type":"ChangeSpec", "stmt":"...",
  "implements":["req:..."],
  "ix":["ix:A","ix:B","ix:C"],
  "rollout_flag":"flag.name",
  "accept":["All IX tests pass","E2E spans present"],
  "owner":"<team>","status":"Open","simple?":false,
  "architecture?":["arch:data-flow:<slug>","arch:error-strategy:<slug>","arch:business-logic:<slug>"]
}
```

## Architecture (DataFlow, ErrorStrategy, BusinessLogic)
```json
{
  "id":"arch:<type>:<slug>", "type":"Architecture",
  "architecture_type":"DataFlow|ErrorStrategy|BusinessLogic|Integration",
  "stmt":"Purpose and scope",
  "diagram?":"<mermaid or text description>",
  "flows":[
    {
      "name":"<flow name>",
      "steps":["step1 → step2 → step3"],
      "services":["service1","service2"],
      "data":["<data passed between services>"],
      "async?":true,
      "events?":["event1","event2"]
    }
  ],
  "patterns":["pattern1","pattern2"],
  "error_handling?":{
    "circuit_breakers":["<service>"],
    "fallbacks":["<fallback strategy>"],
    "compensation":["<compensation workflow>"]
  },
  "state_machines?":[
    {
      "name":"<state machine name>",
      "states":["state1","state2","state3"],
      "transitions":["state1 → state2","state2 → state3"],
      "triggers":["<event/condition>"]
    }
  ],
  "depends_on":["capability:...","contract:..."],
  "owner":"<team>","status":"Open"
}
```

## Contract (API)
```json
{
  "id":"contract:api:<slug>","type":"Contract",
  "stmt":"Purpose + endpoint family",
  "endpoints":[
    {"method":"POST","path":"/media/presign","req":{"mime":"...","sha256":"..."},"res":{"upload_url":"...","media_id":"..."}}
  ],
  "error_taxonomy":[{"code":"400","name":"BadRequest"}, {"code":"429","name":"RateLimit"}],
  "idempotency":{"strategy":"key","header":"x-idempotency-key"},
  "timeouts_ms":{"default":8000},
  "rate_limit":{"bucket":"user","rps":10},
  "versioning":{"semver":"v2","breaking_notes":"added alt_text"},
  "observability":{"logs":["api.req","api.res","api.err"],"metrics":["latency_ms","error_rate"],"span":"api.media.presign"},
  "security":{"authZ":"user:write","scopes":["media:write"]},
  "test":{"contract":["happy","invalid-mime","rate-limited"]},
  "status":"Open"
}
```

## Contract (Data)
```json
{
  "id":"contract:data:<slug>","type":"Contract",
  "stmt":"Schema + lifecycle",
  "schema":{"table":"media","columns":[{"name":"id","type":"uuid","pk":true},{"name":"owner_id","type":"uuid","index":true}]},
  "indices":[["owner_id","created_at"]],
  "migration":{"id":"2025_11_01_media.sql","backfill":"N/A"},
  "retention":{"policy":"keep-variants","ttl_days":null},
  "pii":{"contains":false,"fields":[]},
  "region":{"primary":"us-east-1","dr":"us-west-2"},
  "test":{"migration":["apply","rollback"]},
  "status":"Open"
}
```

## Scenario
```json
{"id":"scenario:<slug>","type":"Scenario","stmt":"Given ... When ... Then ...","owner":"QA","status":"Open"}
```

## Requirement
```json
{"id":"req:<slug>","type":"Requirement","stmt":"Functional or Non-Functional requirement","owner":"PM","status":"Open"}
```

## UXFlow
```json
{"id":"ux:<slug>","type":"UXFlow","states":["loading","ready","empty","error"],"a11y":["alt text required"],"i18n":["en","es"],"status":"Open"}
```

## Screen
```json
{
  "id":"screen:<slug>","type":"Screen",
  "route":"/<path>/{id?}",
  "entry_points":["CTA:...","DeepLink:...","NavItem:..."],
  "guards":{"auth_role":["..."],"plan":["..."],"feature_flag":["..."],"unsaved_changes_guard":true},
  "layout":{"type":"detail|list|grid|wizard|map","breakpoints":["sm","md","lg"]},
  "depends_on":["contract:...","data:..."],
  "status":"Open"
}
```

## NavigationSpec
```json
{
  "id":"nav:<from>-><to>","type":"NavigationSpec",
  "action":"push|replace|modal|sheet",
  "params":{"id?":"string","source?":"string"},
  "back_behavior":"pop|dismiss|custom",
  "tests":[
    {"name":"deep_link_opens_detail","given":"url:/item/123","then":"route_is:/item/123"}
  ],
  "status":"Open"
}
```

## UIComponentContract
```json
{
  "id":"ui-component:<entity>-form","type":"UIComponentContract",
  "props":{"entityId?":"string"},
  "state_machine":["Idle","Editing","Submitting","Success|InlineError"],
  "validation":{"client_rules":["..."],"server_rules":["..."]},
  "events":["submit","cancel","delete"],
  "links":{"tracking_events":["..."],"spans":["..."]},
  "visual_spec_ref":"visual:...",
  "a11y":{"keyboard_nav":true,"aria_labels":["..."]},
  "i18n":{"copy_keys":["..."]},
  "status":"Open"
}
```

## SettingsSpec
```json
{
  "id":"settings:<key>","type":"SettingsSpec",
  "scope":"user|tenant|device",
  "default":"value",
  "controls":"toggle|select|range",
  "policy":{"admin_enforced?":false,"allowed_values?":["..."]},
  "migration":{"from_version":"vN","fallback":"value"},
  "status":"Open"
}
```

## TutorialSpec
```json
{
  "id":"tutorial:<feature>","type":"TutorialSpec",
  "triggers":["first_use_of:<screen>","low_adoption_below:<metric>"],
  "steps":["coachmark:<selector>","highlight:<selector>","checklist:<id>"],
  "completion":{"event":"tutorial_completed","cooldown_days":90},
  "status":"Open"
}
```

## NotificationSpec
```json
{
  "id":"notification:<topic>","type":"NotificationSpec",
  "channels":["in_app","push","email"],
  "template_ids":{"in_app":"tpl_...","push":"tpl_..."},
  "throttle":{"max_per_hour":2},
  "preference_link":"settings:notifications.<topic>",
  "status":"Open"
}
```

## BadgeRule
```json
{
  "id":"badge:<surface>","type":"BadgeRule",
  "increments_on":["event:<name>","query:unread_count"],
  "resets_on":["screen_visit:<slug>","action:<name>"],
  "status":"Open"
}
```

## VisualSpec
```json
{
  "id":"visual:<component>","type":"VisualSpec",
  "tokens":{"color.bg":"var(--bg-surface)","space.x":16,"radius":12},
  "modes":{"light":true,"dark":true,"high_contrast":true},
  "depends_on":["tokens:v1"],
  "status":"Open"
}
```

## StyleGuide
```json
{
  "id":"style-guide:app","type":"StyleGuide",
  "sections":["colors","typography","spacing","layout","motion","accessibility"],
  "platforms":["web","ios","android"],
  "owner":"Design",
  "status":"Open"
}
```

## DesignTokens
```json
{
  "id":"tokens:v1","type":"DesignTokens",
  "tokens":{
    "colors":{"primary":"#0066FF","secondary":"#6B46C1","success":"#10B981","warning":"#F59E0B","error":"#EF4444"},
    "typography":{"fontFamily":{"sans":"Inter, system-ui","mono":"Fira Code"},"fontSize":{"xs":"0.75rem","sm":"0.875rem","base":"1rem"}},
    "spacing":{"base":4,"scale":[4,8,12,16,24,32,48,64,96,128]},
    "radii":{"sm":4,"md":8,"lg":12,"xl":16,"full":9999},
    "breakpoints":{"sm":640,"md":768,"lg":1024,"xl":1280}
  },
  "modes":["light","dark","high_contrast"],
  "implements":"style-guide:app",
  "owner":"Design",
  "status":"Open"
}
```

## ComponentLibrary
```json
{
  "id":"components:v1","type":"ComponentLibrary",
  "components":["Button","Input","Select","Checkbox","Radio","Toggle","List","Card","Table","Badge","Avatar","Tabs","Modal","Sheet","Toast","Skeleton","Empty","Error","Spinner","Progress","Pagination","Divider","Tooltip","Popover"],
  "component_mapping":{
    "Button":{"tokens":["colors.primary","typography.fontSize","spacing.scale","radii.md"],"variants":["primary","secondary","outline","ghost","link"],"sizes":["sm","md","lg"]},
    "Input":{"tokens":["colors.neutral","typography.fontSize","spacing.scale","radii.sm"],"states":["default","hover","focus","disabled","error"]},
    "Card":{"tokens":["colors.surface","shadows.md","radii.lg","spacing.scale"],"variants":["default","elevated","outlined"]}
  },
  "uses":"tokens:v1",
  "owner":"Design + Engineering",
  "status":"Open"
}
```

## InteractionSpec (Client-side with UI state clustering)
```json
{
  "id":"ix:client:<slug>","type":"InteractionSpec",
  "lane":"Client",
  "method":"Component.action()","interface":"UI","operation":"<Action>",
  "state":{"auth_state":"authenticated","network":"online","theme":"light","device":"mobile","permission":"granted","empty":false},
  "pre":["..."],
  "in":{"user_action":"...","form_data?":"..."},
  "eff":["UI state changes","navigation","cache updates","optimistic UI"],
  "err":{"recoverable":["network_error","validation_error"],"terminal":["permission_denied"],"display":"inline|toast|modal"},
  "res":{"timeout_ms":5000,"retry":{"strategy":"linear","max":2},"offline_queue":true},
  "obs":{"logs":["ui.action"],"metrics":["interaction_time"],"analytics":["event.click"]},
  "a11y":{"keyboard_shortcut":"Ctrl+S","aria_label":"Save item","focus_trap":true},
  "i18n":{"copy_keys":["button.save","error.network"],"rtl_support":true},
  "visual_spec_ref":"visual:...",
  "test":{"mocks":["api"],"acc":["Given user on form","When clicks save","Then item saved"]},
  "depends_on":["contract:...","visual:..."],
  "owner":"<team>","est_h":1,"status":"Open"
}
```

## Test
```json
{"id":"test:<slug>","type":"Test","kind":"unit|integration|e2e|perf|security|chaos","targets":["ix:...","contract:...","scenario:..."],"fixtures":["..."],"status":"Open"}
```

## Policy
```json
{"id":"policy:<slug>","type":"Policy","stmt":"What is enforced and where","enforcement_points":["api.gateway","worker.pipeline"],"exceptions":[],"auditability":true,"status":"Open"}
```

## RefactorSpec
```json
{"id":"refactor:<slug>","type":"RefactorSpec","stmt":"Introduce shared retry lib and supersede local retries","supersedes":["ix:A","ix:B"],"status":"Open"}
```

## ADR (decision)
```json
{"id":"adr:<slug>","type":"ADR","stmt":"Decision & rationale","options":["A","B"],"chosen":"A","rationale":"...","status":"Ready"}
```

## OpenQuestion
```json
{"id":"q:<slug>","type":"OpenQuestion","stmt":"Unknown max upload size on mobile","owner":"Product","impact":8,"blocks":["contract:media-presign","ix:upload.s3.fresh"],"due_by":"2025-11-05","status":"Open"}
```

## Delta ops (newline-delimited JSON for `deltas.ndjson`)
```text
{"op":"add_node","node":{"id":"contract:auth-refresh","type":"Contract","stmt":"...","status":"Open"}}
{"op":"add_edge","from":"contract:auth-refresh","to":"ix:compose.auth.refresh.expired","type":"depends_on"}
{"op":"update_node","id":"ix:compose.s3.put.fresh","patch":{"status":"Ready"}}
{"op":"record_unaccounted","id":"contract:media","patch":{"missing":["retention","region"]}}
{"op":"promote_status","id":"scenario:compose-happy","to":"Ready"}
{"op":"retire_node","id":"contract:posts-v1"}
{"op":"split_node","id":"component:media","into":["component:media-api","component:media-worker"]}
{"op":"merge_nodes","ids":["policy:rate-limit-a","policy:rate-limit-b"],"into":"policy:rate-limit"}
```
