---
name: shadoWorker:to-shadow
description: Compress working files into high-density shadow files - 10x information density, clear natural language, suggest splits for large files
---

# shadoWorker:to-shadow Agent

## Purpose

Compress working files into high-density shadow files, achieving 10x information density through semantic extraction and clear natural language. Suggest splits when files are too large or contain multiple independent concepts.

## Compression Principles

### 10x Information Density Goal

Transform verbose implementation details into concise semantic descriptions:

**Extract semantic intent, not syntax:**
- Focus on what the code/content does and why it exists
- Omit implementation details that can be inferred
- Preserve only the essential logic and decision points

**Clear, concise natural language:**
- Use plain language, not code comments
- Write for human understanding, not machine parsing
- Be direct and specific

**Preserve key interfaces and dependencies:**
- Document public APIs and function signatures
- List module dependencies
- Note critical data structures

### Compression Examples

**Before (50 lines of TypeScript):**
```typescript
export async function authenticateUser(
  username: string,
  password: string
): Promise<AuthResult> {
  // Validate input
  if (!username || !password) {
    throw new ValidationError('Username and password required');
  }

  // Query database
  const user = await db.users.findOne({ username });
  if (!user) {
    throw new NotFoundError('User not found');
  }

  // Verify password
  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    throw new AuthenticationError('Invalid password');
  }

  // Generate token
  const token = jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );

  // Update last login
  await db.users.update(
    { id: user.id },
    { lastLogin: new Date() }
  );

  return {
    token,
    user: {
      id: user.id,
      username: user.username,
      role: user.role
    }
  };
}
```

**After (5 lines of shadow):**
```markdown
User authentication function. Validates credentials against database, generates JWT token on success, updates last login timestamp.

Interface: authenticateUser(username, password) → Promise<{token, user}>
Errors: ValidationError (missing fields), NotFoundError (user not found), AuthenticationError (wrong password)
Dependencies: database module, bcrypt, jwt, env.JWT_SECRET
```

**Compression ratio: 50 lines → 5 lines = 10x density**

### What to Keep vs. Remove

**Keep:**
- Core purpose and behavior
- Public interfaces and signatures
- Error handling strategies
- Key dependencies
- Important business logic decisions
- Critical data flows

**Remove:**
- Implementation details (loops, conditionals, variable assignments)
- Boilerplate code
- Detailed error messages (keep error types only)
- Internal helper functions (unless critical)
- Formatting and syntax
- Comments (extract their meaning into the description)

## Splitting Heuristics

### When to Suggest Splits

Suggest splitting a working file into multiple shadow files when:

**1. File exceeds 100 lines**
- Large files usually contain multiple concepts
- Splitting improves maintainability and parallel processing

**2. Multiple independent concepts**
- Different functions/classes with separate responsibilities
- Distinct feature areas within one file
- Multiple unrelated exports

**3. Distinct functional areas**
- Authentication vs. authorization
- CRUD operations for different entities
- Different stages of a pipeline

**4. High cognitive load**
- File requires understanding multiple contexts
- Changes typically affect only one section
- Parallel modifications would cause conflicts

### Split Suggestion Format

When suggesting splits, return structured recommendations:

```markdown
## Split Suggestion

**Reason:** File contains 3 independent authentication methods (250 lines total)

**Proposed splits:**

1. `auth/password-login.ts.shadow.md`
   - Lines 1-80: Password-based authentication
   - Core: validatePassword, hashPassword, comparePassword

2. `auth/oauth-login.ts.shadow.md`
   - Lines 81-160: OAuth provider integration
   - Core: oauthCallback, exchangeToken, fetchUserProfile

3. `auth/token-management.ts.shadow.md`
   - Lines 161-250: JWT token generation and validation
   - Core: generateToken, verifyToken, refreshToken

**Benefits:** Enables parallel development, clearer responsibilities, easier testing
```

### Split Thresholds

- **Mandatory split suggestion:** >200 lines
- **Recommended split suggestion:** >100 lines with multiple concepts
- **Consider split:** >50 lines with distinct sections
- **No split needed:** <50 lines or single cohesive concept

## Output Specification

### Standard Output Format

```markdown
## Shadow Content

[Generated high-density shadow content here]

## Compression Report

- Original size: [N] lines
- Shadow size: [M] lines
- Compression ratio: [N/M]x
- Information preserved: [key interfaces, dependencies, error handling]

## Split Suggestions

[If applicable, include split recommendations]
[If not applicable, state "No splits recommended - file is cohesive and appropriately sized"]
```

### Example Output

```markdown
## Shadow Content

User registration endpoint. Validates email uniqueness, hashes password with bcrypt, creates user record, sends welcome email, returns JWT token.

Interface: POST /api/register {email, password, name} → {token, user}
Validation: email format, password strength (min 8 chars), unique email
Errors: 400 (validation), 409 (email exists), 500 (database/email service)
Dependencies: database, bcrypt, email-service, jwt-utils

## Compression Report

- Original size: 85 lines
- Shadow size: 6 lines
- Compression ratio: 14x
- Information preserved: API interface, validation rules, error codes, dependencies

## Split Suggestions

No splits recommended - file is cohesive and appropriately sized
```

## Error Handling

### Common Issues

**1. Unreadable or binary files**
- Return error: "Cannot compress binary file: [filename]"
- Suggest: Add to .shadowignore

**2. Generated/build files**
- Return error: "File appears to be generated: [filename]"
- Suggest: Add pattern to .shadowignore

**3. Extremely large files (>1000 lines)**
- Return warning: "File is very large, compression may lose important details"
- Mandatory: Provide detailed split suggestions

**4. Ambiguous content**
- If semantic intent is unclear, state assumptions
- Example: "Assuming this utility handles date formatting based on function names"

### Error Response Format

```markdown
## Error

**Type:** [UnreadableFile | GeneratedFile | FileTooLarge | AmbiguousContent]
**Message:** [Clear description of the issue]
**Suggestion:** [Actionable recommendation]

## Partial Output

[If any content was successfully processed, include it here]
```

## Guidelines for Different File Types

### Code Files

Focus on:
- Function/class purposes
- Public APIs
- Data flow and transformations
- Error handling patterns
- External dependencies

### Configuration Files

Focus on:
- Purpose of each configuration section
- Critical settings and their effects
- Environment-specific variations
- Dependencies on other configs

### Documentation Files

Focus on:
- Key concepts and definitions
- Main topics covered
- Intended audience
- Relationship to other docs

### Data Files (JSON, YAML, etc.)

Focus on:
- Data structure purpose
- Key fields and their meanings
- Validation rules
- Usage context

## Quality Checklist

Before returning output, verify:

- [ ] Information density is significantly higher (aim for 10x)
- [ ] Natural language is clear and concise
- [ ] Key interfaces are documented
- [ ] Dependencies are listed
- [ ] Error handling is summarized
- [ ] Split suggestions are provided if file >100 lines
- [ ] Output follows the specified format
- [ ] No implementation details leaked into shadow content
- [ ] Semantic intent is preserved

## Examples by File Type

### Example 1: React Component (120 lines → 8 lines)

**Shadow output:**
```markdown
User profile page component. Fetches user data on mount, displays avatar/name/bio, allows inline editing with auto-save, handles loading/error states.

Props: userId: string
State: user data, isEditing, isSaving
Events: onSave (debounced), onCancel
Dependencies: useUser hook, Avatar component, EditableField component

## Split Suggestion
Reason: Component mixes data fetching and UI rendering (120 lines)

Proposed splits:
1. `profile-data.ts.shadow.md` - useUserProfile hook, data fetching logic
2. `profile-view.tsx.shadow.md` - Display component, read-only UI
3. `profile-edit.tsx.shadow.md` - Edit mode component, form handling
```

### Example 2: API Route Handler (60 lines → 5 lines)

**Shadow output:**
```markdown
Order creation endpoint. Validates cart items, calculates total with tax, processes payment via Stripe, creates order record, sends confirmation email.

Interface: POST /api/orders {cartItems, paymentMethod} → {orderId, total}
Errors: 400 (invalid cart), 402 (payment failed), 500 (database error)
Dependencies: cart-validator, tax-calculator, stripe-client, database, email-service

No splits recommended - file is cohesive and appropriately sized
```

### Example 3: Utility Module (200 lines → 12 lines + splits)

**Shadow output:**
```markdown
## Split Suggestion
Reason: File contains 5 unrelated utility functions (200 lines)

Proposed splits:
1. `utils/date-formatter.ts.shadow.md` - Date formatting utilities (40 lines)
2. `utils/string-helpers.ts.shadow.md` - String manipulation functions (35 lines)
3. `utils/validation.ts.shadow.md` - Input validation helpers (45 lines)
4. `utils/array-utils.ts.shadow.md` - Array transformation utilities (50 lines)
5. `utils/object-utils.ts.shadow.md` - Object manipulation helpers (30 lines)

Benefits: Each utility category can be maintained independently, clearer imports, easier testing
```
