# Safe Alternatives to Eval in Bash Scripts

## Security Policy

**⚠️ NEVER use `eval` in production scripts without security review.**

The `eval` command executes arbitrary code and is a critical security vulnerability if attacker-controlled data flows into it.

---

## Common Use Cases and Safe Alternatives

### 1. Command Construction (CRITICAL)

#### ❌ UNSAFE - String Concatenation + Eval
```bash
# DANGER: Command injection vulnerability
cmd="./deploy.sh --env production --region ${region}"
eval "$cmd"

# Attack: region="; rm -rf / #"
# Executes: ./deploy.sh --env production --region ; rm -rf / #
```

#### ✅ SAFE - Array Expansion
```bash
# Safe: Array handles spaces, quotes, special characters correctly
cmd_array=(
    "./deploy.sh"
    "--env" "production"
    "--region" "${region}"
)
"${cmd_array[@]}"

# Attack blocked: region value treated as single argument
# Even "region='; rm -rf / #'" is passed safely as a literal string
```

**Why it's safe:**
- Each array element is a separate argument
- Special characters are not interpreted as shell syntax
- Quotes and spaces handled automatically

---

### 2. Dynamic Variable Assignment

#### ❌ UNSAFE - Eval for Variable Names
```bash
# DANGER: Code injection if var_name is malicious
var_name="CONFIG_${key}"
eval "${var_name}='${value}'"

# Attack: var_name="x; malicious_cmd #"
```

#### ✅ SAFE - Declare Builtin
```bash
# Safe: declare is a bash builtin, not code evaluation
var_name="CONFIG_${key}"
declare -g "${var_name}=${value}"

# Or use printf with declare:
declare -g "$(printf '%s=%s' "$var_name" "$value")"
```

**Additional options:**
```bash
# For simple cases, use nameref (bash 4.3+)
declare -n var_ref="$var_name"
var_ref="$value"

# For associative arrays
declare -A config
config["$key"]="$value"
```

---

### 3. Variable Indirection

#### ❌ UNSAFE - Eval for Reading Variables
```bash
# DANGER: Variable name could contain commands
var_name="USER_${id}"
eval "value=\${$var_name}"
```

#### ✅ SAFE - Parameter Expansion
```bash
# Safe: Use bash parameter expansion (indirect expansion)
var_name="USER_${id}"
value="${!var_name}"

# Or use printf:
value=$(printf '%s' "${!var_name}")
```

---

### 4. Conditional Execution

#### ❌ UNSAFE - Eval for Dynamic Commands
```bash
# DANGER: Command from variable
command="process_${action}"
eval "$command"
```

#### ✅ SAFE - Case Statement
```bash
# Safe: Explicit enumeration of allowed commands
case "$action" in
    start)
        process_start
        ;;
    stop)
        process_stop
        ;;
    restart)
        process_restart
        ;;
    *)
        echo "Error: Invalid action '$action'" >&2
        exit 1
        ;;
esac
```

---

### 5. Dynamic Function Calls

#### ❌ UNSAFE - Eval for Function Names
```bash
# DANGER: Function name could be malicious
func_name="validate_${type}"
eval "$func_name" "$data"
```

#### ✅ SAFE - Allowlist + Direct Call
```bash
# Safe: Validate against allowlist first
allowed_types=("email" "phone" "postal")

if [[ " ${allowed_types[*]} " =~ " ${type} " ]]; then
    # Sanitized - safe to construct function name
    "validate_${type}" "$data"
else
    echo "Error: Invalid type '$type'" >&2
    exit 1
fi
```

---

### 6. Command with Optional Arguments

#### ❌ UNSAFE - String Building
```bash
# DANGER: Injection via options
cmd="mysql -h ${host} -u ${user}"
[[ -n "$password" ]] && cmd="$cmd -p${password}"
eval "$cmd"
```

#### ✅ SAFE - Array Building
```bash
# Safe: Build array conditionally
cmd_array=(
    "mysql"
    "-h" "${host}"
    "-u" "${user}"
)

if [[ -n "$password" ]]; then
    cmd_array+=("-p${password}")
fi

if [[ -n "$database" ]]; then
    cmd_array+=("${database}")
fi

"${cmd_array[@]}"
```

---

## Exceptions: When Eval Might Be Acceptable

In rare cases, eval may be acceptable if:

1. ✅ Input is 100% controlled (hardcoded constants only)
2. ✅ Security review has been performed
3. ✅ Alternative approaches are truly impossible
4. ✅ Extensive input validation is in place

**Example of acceptable use:**
```bash
# Hardcoded arithmetic expression (no variables)
result=$(eval "echo \$((2 + 2))")

# Better alternative: Use arithmetic expansion directly
result=$((2 + 2))
```

---

## Security Scanning

Run the security check before committing:

```bash
./scripts/check-no-eval.sh
```

This will scan all shell scripts and flag any dangerous eval usage.

---

## Additional Resources

- [CWE-95: Eval Injection](https://cwe.mitre.org/data/definitions/95.html)
- [OWASP Code Injection](https://owasp.org/www-community/attacks/Code_Injection)
- [Bash Arrays Guide](https://mywiki.wooledge.org/BashGuide/Arrays)
- [ShellCheck - Shell Script Analyzer](https://www.shellcheck.net/)

---

## Quick Reference Table

| Use Case | ❌ Unsafe (eval) | ✅ Safe Alternative |
|----------|-----------------|---------------------|
| Command execution | `eval "$cmd"` | `"${cmd_array[@]}"` |
| Set variable | `eval "$var=$val"` | `declare -g "$var=$val"` |
| Read variable | `eval "x=\${$var}"` | `x="${!var}"` |
| Dynamic function | `eval "$func"` | `case + allowlist` |
| Optional args | `eval "$cmd $opts"` | Array with `+=()` |

---

**Last Updated:** 2025-10-23
**Security Level:** CRITICAL
**Reviewed By:** Security Audit Task #6
