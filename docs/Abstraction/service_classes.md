# Service classes

Everything that resides in `app/services`.

Service classes represent operations that coordinate changes between models (such as entities and value objects). Changes impact the state of the application (.new!, .save!, .update!).

1. When an object makes no changes to the state of the application, then it's not a service. It may be a query object or value object.
2. When there is no operation, there is no need to execute a service. The class would probably be better designed as a plain query object or value object.
3. Query objects live under `app/services/queries`, namespaced as `module Queries`. They're housed alongside service classes but are exempt from the "changes state" rule above — that's the intentional carve-out, not a contradiction of it.

When implementing a service class, follow these patterns:

## 1. Initializer arguments

1. The service class initializer should contain, in its arguments:
   1. A model instance that is being acted upon. This should be the first positional argument of the initializer. The argument name is left to the developer's discretion, such as `course`, `enrolment`, `project`.
   2. `current_user:` is an optional keyword argument, used only when the service needs the user as data — e.g. recording who performed an action. It is never how the service decides whether the action is allowed. Authorization (who can act) is a Pundit policy concern, checked by the controller before the service runs — never re-derived or re-checked inside the service itself.
   3. When the service has no use for a user object at all (a background job, a side-effect of another operation), the `current_user:` argument is not needed.
   4. For all additional data required by a service, explicit keyword arguments are recommended. Only split into `params:`/`options:` hashes once a service's argument list gets long (roughly 4–5+ keyword arguments, or you're passing configuration that isn't a model attribute) — don't do this preemptively for a two- or three-argument service.

```ruby
# course: A model instance that is being acted upon.
# offsets: New per-lecturer capacity offsets to apply.
# excluded_ids: Enrolment IDs to exclude from auto-calculated capacity.
def initialize(course, offsets:, excluded_ids:)
  @course = course
  @offsets = offsets
  @excluded_ids = excluded_ids
end
```

```ruby
# issue: A model instance that is being acted upon.
# current_user: Optional — only present when needed as data (e.g. audit
#   logging). Never used to gate the operation; that's Pundit's job.
# params: Model properties that will be assigned directly.
# options: Extra configuration for this service, not model properties.
def initialize(issue, current_user: nil, params: {}, options: {})
  @issue = issue
  @current_user = current_user
  @params = params
  @options = options
end
```

## 2. Method naming

Query objects (`app/services/queries`) implement a single public `#execute` method, no arguments. All required data is passed in through the initializer.

Service classes that change state use an explicit, bang-verb instance method matching the action instead — `confirm!`, `remove!`, `revert!`, `update!`. Not `execute`, not `call`. `#execute` on a state-changing service hides the side effect at the call site the same way `#call` does; the verb needs to be visible where it's called.

```ruby
# good — command service, bang-verb, all data via the initializer
SupervisorCapacityUpdater.new(course, offsets: offsets, excluded_ids: excluded_ids).update!

# good — query object, single #execute
Queries::SupervisorCapacityCalculator.new(course).execute

# avoid — a generic `call`, or `execute` on a state-changing service, obscures what happens
SupervisorCapacityUpdater.new(course, offsets: offsets, excluded_ids: excluded_ids).call
```

## 3. Return a rich result object, not a boolean

If a return value is needed, the service should return its result via a `Result` object — never a bare `true`/`false`, and never an ActiveRecord instance on its own.

- A `Result` object can carry a success/failure state, an error list, and whatever data the caller actually needs — named and typed, not a generic hash the caller has to know the shape of.
- `success?`/`error?` are only required on a `Result` that has a genuine second outcome — a `blocked_reason`, an `errors` array, or equivalent. Don't add them to a `Result` that always succeeds; that's aliasing nothing.

```ruby
class SupervisorCapacityUpdater
  class Result
    include ServiceResult # provides success?/error? from `errors.empty?`

    attr_reader :course, :errors

    def initialize(updated:, course:, errors: [])
      @updated = updated
      @course = course
      @errors = errors
    end

    def updated? = @updated
  end
end
```

```ruby
# ServiceResult — shared module, mixed into a Result class that has a real failure mode
module ServiceResult
  def success? = errors.empty?
  def error? = !success?
end
```

## 4. Patterns to avoid

1. **Creating class methods closes doors.** Prefer instance methods so a service can be composed, tested, and extended without `self.`-method gymnastics.
2. **Using a generic method name like `call` — or `execute` on a state-changing service — obscures behavior.** `execute` is reserved for query objects, where the verb already lives in the class name (`SupervisorCapacityCalculator#execute`). A state-changing service's whole reason to exist is its side effect, so its method name should say what that side effect is.
3. **Passing services into services via dependency injection obscures behavior.** If a service needs another service's output, instantiate it directly inside the method that needs it (as `SupervisorCapacityUpdater` does with `SupervisorCapacityCalculator`) rather than injecting it through the constructor. This keeps the dependency visible at the point it's used, and avoids needing container/wiring knowledge to trace what a service actually depends on.

### References

[GitLab's service class conventions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/reusing_abstractions.md)